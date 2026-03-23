import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:uuid/uuid.dart';
import '../../database/hive_database.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../models/task_model.dart';
import '../../theme/yamada_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<TaskModel> _allTasks = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedDay = _focusedDay;
    _loadData();
  }

  void _loadData() {
    setState(() {
      _allTasks = YamadaDatabase.getAllTasks();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<TaskModel> _getTasksForDay(DateTime day) {
    return _allTasks.where((task) {
      if (task.dueDate == null) return false;
      return isSameDay(task.dueDate!, day);
    }).toList();
  }

  void _addTaskForDay(DateTime? day) {
    if (day == null) return;
    String title = '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: YamadaTheme.crimson,
        shape: const RoundedRectangleBorder(),
        title: Text('NEW OPERATION', style: YamadaTheme.heading3),
        content: TextField(
          autofocus: true,
          style: YamadaTheme.body,
          decoration: InputDecoration(
            hintText: 'OPERATION TITLE',
            hintStyle: YamadaTheme.body.copyWith(color: YamadaTheme.inkGhost),
          ),
          onChanged: (v) => title = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL', style: YamadaTheme.bodyBold),
          ),
          TextButton(
            onPressed: () {
              if (title.trim().isNotEmpty) {
                final newTask = TaskModel(
                  id: const Uuid().v4(),
                  title: title.trim(),
                  dueDate: day,
                  createdAt: DateTime.now(),
                  priority: 'standard',
                );
                YamadaDatabase.addTask(newTask);
                _loadData();
              }
              Navigator.pop(ctx);
            },
            child: Text('DEPLOY', style: YamadaTheme.bodyBold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YamadaTheme.crimson,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('ANALYTICS', style: YamadaTheme.heading1.copyWith(color: YamadaTheme.ink)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: YamadaTheme.ink,
          labelColor: YamadaTheme.ink,
          unselectedLabelColor: YamadaTheme.ink.withValues(alpha: 0.5),
          tabs: const [
            Tab(text: 'OVERVIEW'),
            Tab(text: 'CALENDAR'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildCalendarTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('7-DAY OPERATION HISTORY', style: YamadaTheme.heading2),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: _buildLineChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    final now = DateTime.now();
    final List<FlSpot> spots = [];

    // Calculate completions for the past 7 days
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final completed = _allTasks.where((t) => 
        t.isCompleted && 
        t.dueDate != null && 
        isSameDay(t.dueDate!, day)
      ).length;
      spots.add(FlSpot((6 - i).toDouble(), completed.toDouble()));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: YamadaTheme.ink.withValues(alpha: 0.1),
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final date = now.subtract(Duration(days: 6 - value.toInt()));
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${date.day}/${date.month}',
                    style: YamadaTheme.caption.copyWith(color: YamadaTheme.inkSubtle),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: YamadaTheme.caption.copyWith(color: YamadaTheme.inkSubtle),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: YamadaTheme.ink,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: YamadaTheme.ink.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarTab() {
    final selectedTasks = _selectedDay != null ? _getTasksForDay(_selectedDay!) : [];

    return Column(
      children: [
        TableCalendar<TaskModel>(
          firstDay: DateTime.utc(2020, 10, 16),
          lastDay: DateTime.utc(2030, 3, 14),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
              HapticFeedback.selectionClick();
            });
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          eventLoader: _getTasksForDay,
          calendarStyle: CalendarStyle(
            markerDecoration: BoxDecoration(
              color: YamadaTheme.ink,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: YamadaTheme.ink,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: YamadaTheme.ink.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            defaultTextStyle: YamadaTheme.body.copyWith(color: YamadaTheme.white),
            weekendTextStyle: YamadaTheme.body.copyWith(color: YamadaTheme.white.withValues(alpha: 0.7)),
            outsideTextStyle: YamadaTheme.body.copyWith(color: YamadaTheme.white.withValues(alpha: 0.3)),
          ),
          headerStyle: HeaderStyle(
            titleTextStyle: YamadaTheme.heading2.copyWith(color: YamadaTheme.white),
            formatButtonTextStyle: YamadaTheme.caption.copyWith(color: YamadaTheme.crimson),
            formatButtonDecoration: BoxDecoration(
              color: YamadaTheme.white,
              borderRadius: BorderRadius.circular(12),
            ),
            leftChevronIcon: const Icon(Icons.chevron_left, color: YamadaTheme.white),
            rightChevronIcon: const Icon(Icons.chevron_right, color: YamadaTheme.white),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: YamadaTheme.caption.copyWith(color: YamadaTheme.white.withValues(alpha: 0.7)),
            weekendStyle: YamadaTheme.caption.copyWith(color: YamadaTheme.white.withValues(alpha: 0.5)),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Container(
            color: YamadaTheme.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: selectedTasks.isEmpty
                      ? Center(
                          child: Text('NO OPERATIONS SCHEDULED', style: YamadaTheme.heading2.copyWith(color: YamadaTheme.inkSubtle)),
                        )
                      : AnimationLimiter(
                          child: ListView.builder(
                            itemCount: selectedTasks.length,
                            itemBuilder: (context, index) {
                              final task = selectedTasks[index];
                              return AnimationConfiguration.staggeredList(
                                position: index,
                                duration: const Duration(milliseconds: 400),
                                child: SlideAnimation(
                                  horizontalOffset: 50.0,
                                  child: FadeInAnimation(
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: task.isCompleted ? YamadaTheme.ink.withValues(alpha: 0.05) : YamadaTheme.white,
                                        border: Border.all(color: YamadaTheme.ink, width: 2),
                                        boxShadow: task.isCompleted ? [] : [
                                          BoxShadow(color: YamadaTheme.ink, offset: const Offset(4, 4))
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                                            color: YamadaTheme.ink,
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Text(
                                              task.title.toUpperCase(),
                                              style: task.isCompleted 
                                                ? YamadaTheme.heading3.copyWith(decoration: TextDecoration.lineThrough, color: YamadaTheme.inkSubtle)
                                                : YamadaTheme.heading3.copyWith(color: YamadaTheme.ink),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _addTaskForDay(_selectedDay),
                  icon: Icon(Icons.add, color: YamadaTheme.crimson),
                  label: Text('DEPLOY OPERATION', style: YamadaTheme.bodyBold.copyWith(color: YamadaTheme.crimson)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: YamadaTheme.ink,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const RoundedRectangleBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
