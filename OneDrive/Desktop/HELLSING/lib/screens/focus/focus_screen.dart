import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:uuid/uuid.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../database/hive_database.dart';
import '../../models/focus_session_model.dart';
import '../../services/gamification_service.dart';
import '../../theme/yamada_theme.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen>
    with SingleTickerProviderStateMixin {
  // Duration presets
  static const _presets = [
    {'label': 'POMODORO', 'minutes': 25},
    {'label': 'DEEP WORK', 'minutes': 50},
    {'label': 'FLOW STATE', 'minutes': 90},
    {'label': 'MICRO SPRINT', 'minutes': 5},
  ];
  static const _shortBreak = 5;
  static const _longBreak = 15;

  int _selectedMinutes = 25;
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  bool _showPresets = false;
  bool _showBreakOptions = false;
  int _completedSessions = 0;
  String _selectedLabel = 'POMODORO';

  late AnimationController _pulseController;

  // Custom time
  int _customHours = 0;
  int _customMinutes = 25;
  bool _showCustomPicker = false;

  // Sound mode
  String _soundMode = 'SILENCE'; // SILENCE, STATIC, FORGE

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _loadTodaySessions();
  }

  Future<void> _loadTodaySessions() async {
    final sessions = YamadaDatabase.getAllFocusSessions();
    final now = DateTime.now();
    final todaySessions = sessions.where((s) => 
      s.startTime.year == now.year && 
      s.startTime.month == now.month && 
      s.startTime.day == now.day && 
      s.completed
    );
    if (mounted) {
      setState(() => _completedSessions = todaySessions.length);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _selectPreset(int index) {
    if (_isRunning) return;
    final preset = _presets[index];
    setState(() {
      _selectedMinutes = preset['minutes'] as int;
      _selectedLabel = preset['label'] as String;
      _remainingSeconds = _selectedMinutes * 60;
      _showPresets = false;
      _showCustomPicker = false;
    });
  }

  void _selectCustom() {
    if (_isRunning) return;
    final totalMinutes = _customHours * 60 + _customMinutes;
    if (totalMinutes < 1) return;
    setState(() {
      _selectedMinutes = totalMinutes;
      _selectedLabel = 'CUSTOM';
      _remainingSeconds = totalMinutes * 60;
      _showCustomPicker = false;
      _showPresets = false;
    });
  }

  void _toggleTimer() {
    HapticFeedback.lightImpact();
    setState(() {
      _isRunning = !_isRunning;
    });
    if (_isRunning) {
      _tick();
    }
  }

  void _tick() {
    if (!_isRunning || _remainingSeconds <= 0) return;
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted || !_isRunning) return;
      setState(() {
        _remainingSeconds--;
      });
      if (_remainingSeconds <= 0) {
        _onSessionComplete();
      } else {
        _tick();
      }
    });
  }

  Future<void> _onSessionComplete() async {
    setState(() {
      _isRunning = false;
      _showBreakOptions = true;
    });

    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 200));
    HapticFeedback.mediumImpact();

    final gamification = GamificationService();

    // Log session
    final session = FocusSessionModel(
      id: const Uuid().v4(),
      startTime: DateTime.now().subtract(Duration(minutes: _selectedMinutes)),
      durationMinutes: _selectedMinutes,
      completed: true,
    );
    await YamadaDatabase.addFocusSession(session);

    // Award XP
    await gamification.awardFocusXp(_selectedMinutes);
    setState(() => _completedSessions++);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'SESSION COMPLETE // +${GamificationService.focusXpPerMinute * _selectedMinutes} XP',
            style: YamadaTheme.bodyBold.copyWith(color: YamadaTheme.crimson),
          ),
          backgroundColor: YamadaTheme.ink,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(),
        ),
      );
    }
  }

  void _startBreak(int minutes) {
    setState(() {
      _selectedMinutes = minutes;
      _selectedLabel = minutes == _shortBreak ? 'SHORT BREAK' : 'LONG BREAK';
      _remainingSeconds = minutes * 60;
      _showBreakOptions = false;
      _isRunning = true;
    });
    _tick();
  }

  void _resetTimer() {
    setState(() {
      _remainingSeconds = _selectedMinutes * 60;
      _isRunning = false;
      _showBreakOptions = false;
    });
  }

  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: YamadaTheme.crimson,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('FOCUS', style: YamadaTheme.heading1)
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideX(begin: -0.2, end: 0),
                    // Sound toggle
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          final modes = ['SILENCE', 'STATIC', 'FORGE'];
                          final idx = modes.indexOf(_soundMode);
                          _soundMode = modes[(idx + 1) % modes.length];
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(border: YamadaTheme.hardBorder),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _soundMode == 'SILENCE'
                                  ? Icons.volume_off
                                  : _soundMode == 'STATIC'
                                      ? Icons.graphic_eq
                                      : Icons.hardware,
                              color: YamadaTheme.ink,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(_soundMode, style: YamadaTheme.caption),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(_selectedLabel,
                    style: YamadaTheme.sectionLabel
                        .copyWith(color: YamadaTheme.inkLight)),

                const SizedBox(height: 30),

                // Timer ring
                Center(
                  child: GestureDetector(
                    onTap: _isRunning ? null : () => setState(() => _showPresets = !_showPresets),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background ring
                        SizedBox(
                          width: 240,
                          height: 240,
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: _TimerRingPainter(
                                  progress: _remainingSeconds /
                                      (_selectedMinutes * 60),
                                  isRunning: _isRunning,
                                  pulseValue: _pulseController.value,
                                ),
                              );
                            },
                          ),
                        ),
                        // Time display
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTime(_remainingSeconds),
                              style: YamadaTheme.heading1.copyWith(fontSize: 56),
                            ),
                            if (!_isRunning)
                              Text('TAP TO CHANGE',
                                  style: YamadaTheme.caption
                                      .copyWith(color: YamadaTheme.inkSubtle)),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 600.ms)
                    .scale(begin: const Offset(0.85, 0.85)),

                const SizedBox(height: 24),

                // Preset picker
                if (_showPresets) ...[
                  Container(
                    decoration: BoxDecoration(border: YamadaTheme.hardBorder),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('SELECT DURATION', style: YamadaTheme.sectionLabel),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(_presets.length, (i) {
                            final p = _presets[i];
                            final isActive = _selectedLabel == p['label'];
                            return GestureDetector(
                              onTap: () => _selectPreset(i),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isActive ? YamadaTheme.ink : null,
                                  border: YamadaTheme.hardBorder,
                                ),
                                child: Text(
                                  '${p['minutes']}:00 ${p['label']}',
                                  style: YamadaTheme.caption.copyWith(
                                    color: isActive
                                        ? YamadaTheme.crimson
                                        : YamadaTheme.ink,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => setState(() {
                            _showCustomPicker = !_showCustomPicker;
                          }),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(border: YamadaTheme.hardBorder),
                            alignment: Alignment.center,
                            child: Text('CUSTOM', style: YamadaTheme.caption),
                          ),
                        ),
                        if (_showCustomPicker) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Text('HOURS', style: YamadaTheme.caption),
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      height: 80,
                                      child: ListWheelScrollView.useDelegate(
                                        itemExtent: 30,
                                        onSelectedItemChanged: (v) =>
                                            setState(() => _customHours = v),
                                        childDelegate: ListWheelChildBuilderDelegate(
                                          builder: (ctx, i) => i >= 0 && i <= 4
                                              ? Center(
                                                  child: Text('$i',
                                                      style: YamadaTheme.dataMedium))
                                              : null,
                                          childCount: 5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text('MINUTES', style: YamadaTheme.caption),
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      height: 80,
                                      child: ListWheelScrollView.useDelegate(
                                        itemExtent: 30,
                                        onSelectedItemChanged: (v) =>
                                            setState(() => _customMinutes = v * 5),
                                        childDelegate: ListWheelChildBuilderDelegate(
                                          builder: (ctx, i) => i >= 0 && i <= 11
                                              ? Center(
                                                  child: Text('${i * 5}',
                                                      style: YamadaTheme.dataMedium))
                                              : null,
                                          childCount: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: _selectCustom,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              color: YamadaTheme.ink,
                              alignment: Alignment.center,
                              child: Text('SET CUSTOM',
                                  style: YamadaTheme.caption
                                      .copyWith(color: YamadaTheme.crimson)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.1, end: 0),
                  const SizedBox(height: 16),
                ],

                // Break options after session
                if (_showBreakOptions)
                  Container(
                    decoration: BoxDecoration(border: YamadaTheme.hardBorder),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('SESSION COMPLETE', style: YamadaTheme.heading3),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _startBreak(_shortBreak),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  color: YamadaTheme.ink,
                                  alignment: Alignment.center,
                                  child: Text(
                                    'SHORT BREAK\n${_shortBreak}:00',
                                    textAlign: TextAlign.center,
                                    style: YamadaTheme.caption
                                        .copyWith(color: YamadaTheme.crimson),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _startBreak(_longBreak),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(border: YamadaTheme.hardBorder),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'LONG BREAK\n${_longBreak}:00',
                                    textAlign: TextAlign.center,
                                    style: YamadaTheme.caption,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .scale(begin: const Offset(0.95, 0.95)),

                const SizedBox(height: 24),

                // Control buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _toggleTimer,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          color: YamadaTheme.ink,
                          alignment: Alignment.center,
                          child: Text(
                            _isRunning ? 'PAUSE' : _remainingSeconds < _selectedMinutes * 60 ? 'RESUME' : 'START',
                            style: YamadaTheme.bodyBold.copyWith(
                                color: YamadaTheme.crimson, letterSpacing: 6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _resetTimer,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(border: YamadaTheme.hardBorder),
                        child: Icon(Icons.refresh, color: YamadaTheme.ink, size: 24),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Sessions counter
                Container(
                  decoration: BoxDecoration(border: YamadaTheme.hardBorder),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('TODAY\'S SESSIONS', style: YamadaTheme.sectionLabel),
                      Text('$_completedSessions', style: YamadaTheme.dataLarge),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Daily focus chart
                Container(
                  decoration: BoxDecoration(border: YamadaTheme.hardBorder),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FOCUS // 7 DAYS', style: YamadaTheme.sectionLabel),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 140,
                        child: ValueListenableBuilder<Box<FocusSessionModel>>(
                          valueListenable: YamadaDatabase.focusBox.listenable(),
                          builder: (context, box, _) {
                            final sessions = box.values.toList();
                            return _buildFocusChart(sessions);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFocusChart(List<FocusSessionModel> sessions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));

    final barGroups = days.asMap().entries.map((e) {
      final date = e.value;
      final dailySessions = sessions.where((s) {
        final d = DateTime(s.startTime.year, s.startTime.month, s.startTime.day);
        return d == date && s.completed;
      });
      final minutes = dailySessions.fold(0, (sum, s) => sum + s.durationMinutes).toDouble();

      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: minutes,
            color: YamadaTheme.ink,
            width: 16,
            borderRadius: BorderRadius.zero,
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}m',
                style: YamadaTheme.caption.copyWith(fontSize: 9),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                final date = days[value.toInt()];
                return Text(
                  dayNames[date.weekday - 1],
                  style: YamadaTheme.caption.copyWith(fontSize: 10),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _TimerRingPainter extends CustomPainter {
  final double progress;
  final bool isRunning;
  final double pulseValue;

  _TimerRingPainter({
    required this.progress,
    required this.isRunning,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 12) / 2;

    // Background ring
    final bgPaint = Paint()
      ..color = YamadaTheme.ink.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isRunning ? 6 + pulseValue * 2 : 6;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = YamadaTheme.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );

    // Tick marks
    final tickPaint = Paint()
      ..color = YamadaTheme.ink.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (int i = 0; i < 60; i++) {
      final angle = 2 * pi * i / 60 - pi / 2;
      final innerR = i % 5 == 0 ? radius - 14 : radius - 8;
      canvas.drawLine(
        Offset(center.dx + innerR * cos(angle),
            center.dy + innerR * sin(angle)),
        Offset(center.dx + (radius - 4) * cos(angle),
            center.dy + (radius - 4) * sin(angle)),
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter old) => true;
}
