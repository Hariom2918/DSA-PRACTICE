import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../database/hive_database.dart';
import '../../models/task_model.dart';
import '../../services/gamification_service.dart';
import '../../theme/yamada_theme.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  bool _showArchive = false;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: YamadaTheme.crimson,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_showArchive ? 'ARCHIVE' : 'MISSIONS',
                      style: YamadaTheme.heading1)
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideX(begin: -0.2, end: 0),
                  GestureDetector(
                    onTap: () => setState(() => _showArchive = !_showArchive),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(border: YamadaTheme.hardBorder),
                      child: Text(
                        _showArchive ? 'ACTIVE' : 'ARCHIVE',
                        style: YamadaTheme.caption,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Text(
                _showArchive ? 'COMPLETED OPERATIONS' : 'ACTIVE OPERATIONS',
                style: YamadaTheme.sectionLabel.copyWith(color: YamadaTheme.inkLight),
              ),
            ),
            const Divider(height: 2),
            Expanded(
              child: _showArchive ? _buildArchiveList() : _buildActiveList(),
            ),
          ],
        ),
      ),
      floatingActionButton: _showArchive
          ? null
          : FloatingActionButton(
              onPressed: () => _showTaskForm(context),
              child: const Icon(Icons.add, size: 28),
            ),
    );
  }

  Widget _buildActiveList() {
    return ValueListenableBuilder<Box<TaskModel>>(
      valueListenable: YamadaDatabase.tasksBox.listenable(),
      builder: (context, box, _) {
        final tasks = box.values.where((t) => !t.isArchived).toList();
        
        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('ALL CLEAR', style: YamadaTheme.heading3),
                const SizedBox(height: 8),
                Text('NO ACTIVE MISSIONS',
                    style: YamadaTheme.caption.copyWith(color: YamadaTheme.inkSubtle)),
              ],
            ),
          );
        }

        // Sort by priority (highest first), then by due date
        final sorted = List<TaskModel>.from(tasks)..sort((a, b) {
          final priorityMap = {'critical': 4, 'high': 3, 'standard': 2, 'optional': 1};
          final pA = priorityMap[a.priority] ?? 2;
          final pB = priorityMap[b.priority] ?? 2;
          
          if (pA != pB) return pB.compareTo(pA);
          if (a.dueDate != null && b.dueDate != null) return a.dueDate!.compareTo(b.dueDate!);
          if (a.dueDate != null) return -1;
          return 1;
        });

        // Split overdues
        final now = DateTime.now();
        final overdue = sorted.where((t) => t.dueDate != null && t.dueDate!.isBefore(now) && !t.isCompleted).toList();
        final current = sorted.where((t) => !(t.dueDate != null && t.dueDate!.isBefore(now) && !t.isCompleted)).toList();
        final finalSorted = [...overdue, ...current];

        return AnimationLimiter(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: finalSorted.length,
            itemBuilder: (context, index) {
              final task = finalSorted[index];
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 400),
                child: SlideAnimation(
                  horizontalOffset: 50.0,
                  child: FadeInAnimation(
                    child: _TaskCard(
                      task: task,
                      onComplete: () => _completeTask(task),
                      onDelete: () => _deleteTask(task.id),
                      onEdit: () => _showTaskForm(context, task: task),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildArchiveList() {
    return ValueListenableBuilder<Box<TaskModel>>(
      valueListenable: YamadaDatabase.tasksBox.listenable(),
      builder: (context, box, _) {
        final tasks = box.values.where((t) => t.isArchived).toList();
        
        if (tasks.isEmpty) {
          return Center(
            child: Text('NO ARCHIVED MISSIONS', style: YamadaTheme.heading3),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(border: YamadaTheme.hardBorder),
              child: Opacity(
                opacity: 0.5,
                child: Row(
                  children: [
                    Icon(Icons.check, color: YamadaTheme.ink, size: 18),
                    const SizedBox(width: 12),
                    Expanded(child: Text(task.title, style: YamadaTheme.body)),
                    Text(
                      DateFormat('dd MMM').format(task.createdAt),
                      style: YamadaTheme.caption.copyWith(color: YamadaTheme.inkSubtle),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _completeTask(TaskModel task) async {
    HapticFeedback.mediumImpact();
    final gamification = GamificationService();

    task.isCompleted = true;
    await YamadaDatabase.updateTask(task);
    final xp = await gamification.awardTaskXp(0, task.priority);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('MISSION COMPLETE // +$xp XP',
              style: YamadaTheme.bodyBold.copyWith(color: YamadaTheme.crimson)),
          backgroundColor: YamadaTheme.ink,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(),
        ),
      );
    }
  }

  Future<void> _deleteTask(String id) async {
    await YamadaDatabase.deleteTask(id);
  }

  void _showTaskForm(BuildContext context, {TaskModel? task}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: YamadaTheme.crimson,
      shape: const RoundedRectangleBorder(),
      builder: (ctx) => _TaskFormSheet(task: task),
    );
  }
}

class _TaskCard extends StatefulWidget {
  final TaskModel task;
  final VoidCallback onComplete;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _TaskCard({
    required this.task,
    required this.onComplete,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard> {
  bool _isGlitching = false;

  void _handleComplete() async {
    setState(() => _isGlitching = true);
    await Future.delayed(400.ms);
    if (mounted) {
      widget.onComplete();
      setState(() => _isGlitching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final priorityLabels = {'critical': '●●●', 'high': '●●', 'standard': '●', 'optional': ''};
    final isOverdue = widget.task.dueDate != null && widget.task.dueDate!.isBefore(DateTime.now());

    Widget card = GestureDetector(
      onTap: widget.onEdit,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: YamadaTheme.hardBorder,
          color: isOverdue ? YamadaTheme.ink.withValues(alpha: 0.06) : null,
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: _handleComplete,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  border: Border.all(color: YamadaTheme.ink, width: 2),
                  color: widget.task.isCompleted ? YamadaTheme.ink : null,
                ),
                child: widget.task.isCompleted ? Icon(Icons.check, size: 20, color: YamadaTheme.crimson) : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(widget.task.title, style: YamadaTheme.bodyBold),
                      ),
                      if (widget.task.priority == 'critical' || widget.task.priority == 'high') ...[
                        const SizedBox(width: 8),
                        Text(priorityLabels[widget.task.priority]!,
                            style: TextStyle(
                                color: YamadaTheme.ink, fontSize: 10)),
                      ],
                    ],
                  ),
                  if (widget.task.dueDate != null)
                    Row(
                      children: [
                        Text(
                          DateFormat('dd MMM · HH:mm').format(widget.task.dueDate!),
                          style: YamadaTheme.caption.copyWith(
                            color: isOverdue
                                ? YamadaTheme.ink
                                : YamadaTheme.inkSubtle,
                          ),
                        ),
                        if (isOverdue) ...[
                          const SizedBox(width: 6),
                          Text('OVERDUE',
                              style: YamadaTheme.caption.copyWith(
                                  color: YamadaTheme.ink)),
                        ],
                      ],
                    ),
                ],
              ),
            ),
            GestureDetector(
              onTap: widget.onDelete,
              child: Icon(Icons.close, color: YamadaTheme.inkSubtle, size: 18),
            ),
          ],
        ),
      ),
    );

    if (_isGlitching) {
      card = card.animate()
          .tint(color: YamadaTheme.crimson, duration: 200.ms)
          .shakeX(hz: 8, duration: 400.ms)
          .blur(end: const Offset(4, 0), duration: 200.ms);
    }

    return card;
  }
}

class _TaskFormSheet extends StatefulWidget {
  final TaskModel? task;
  const _TaskFormSheet({this.task});

  @override
  State<_TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<_TaskFormSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  DateTime? _dueDate;
  String _priority = 'standard';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descController = TextEditingController(text: widget.task?.description ?? '');
    _dueDate = widget.task?.dueDate;
    _priority = widget.task?.priority ?? 'standard';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dueDate ?? DateTime.now()),
      );
      setState(() {
        _dueDate = DateTime(date.year, date.month, date.day,
            time?.hour ?? 9, time?.minute ?? 0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.task == null ? 'NEW MISSION' : 'EDIT MISSION',
                style: YamadaTheme.heading3),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              style: YamadaTheme.body,
              decoration: const InputDecoration(labelText: 'MISSION NAME'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              style: YamadaTheme.body,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'DESCRIPTION'),
            ),
            const SizedBox(height: 16),
            // Priority
            Text('PRIORITY', style: YamadaTheme.sectionLabel),
            const SizedBox(height: 8),
            Row(
              children: ['optional', 'standard', 'high', 'critical'].map((p) {
                final labels = {'optional': 'LOW', 'standard': 'MED', 'high': 'HIGH', 'critical': 'CRIT'};
                final isSelected = _priority == p;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _priority = p),
                    child: Container(
                      margin: EdgeInsets.only(right: p != 'critical' ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? YamadaTheme.ink : null,
                        border: YamadaTheme.hardBorder,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        labels[p]!,
                        style: YamadaTheme.caption.copyWith(
                          color: isSelected ? YamadaTheme.crimson : YamadaTheme.ink,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Due date
            GestureDetector(
              onTap: _pickDueDate,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(border: YamadaTheme.hardBorder),
                child: Row(
                  children: [
                    Icon(Icons.schedule, color: YamadaTheme.ink, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _dueDate != null
                          ? DateFormat('dd MMM yyyy · HH:mm').format(_dueDate!)
                          : 'SET DUE DATE',
                      style: YamadaTheme.body,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _saveTask,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                color: YamadaTheme.ink,
                alignment: Alignment.center,
                child: Text(
                  widget.task == null ? 'DEPLOY MISSION' : 'UPDATE MISSION',
                  style: YamadaTheme.bodyBold.copyWith(
                      color: YamadaTheme.crimson, letterSpacing: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveTask() async {
    if (_titleController.text.trim().isEmpty) return;

    if (widget.task == null) {
      final newTask = TaskModel(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        priority: _priority,
        dueDate: _dueDate,
        createdAt: DateTime.now(),
      );
      await YamadaDatabase.addTask(newTask);
    } else {
      final updated = widget.task!;
      updated.title = _titleController.text.trim();
      updated.description = _descController.text.trim();
      updated.priority = _priority;
      updated.dueDate = _dueDate;
      await YamadaDatabase.updateTask(updated);
    }

    if (mounted) Navigator.pop(context);
  }
}
