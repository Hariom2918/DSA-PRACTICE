import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../database/hive_database.dart';
import '../../models/habit_model.dart';
import '../../services/gamification_service.dart';
import '../../theme/yamada_theme.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
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
              child: Text('HABIT WARFARE', style: YamadaTheme.heading1)
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideX(begin: -0.2, end: 0),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Text('DAILY OPERATIONS',
                  style: YamadaTheme.sectionLabel
                      .copyWith(color: YamadaTheme.inkLight)),
            ),
            const Divider(height: 2),
            Expanded(
              child: ValueListenableBuilder<Box<HabitModel>>(
                valueListenable: YamadaDatabase.habitsBox.listenable(),
                builder: (context, box, _) {
                  final habits = box.values.toList();
                  if (habits.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('NO HABITS DEPLOYED', style: YamadaTheme.heading3),
                          const SizedBox(height: 8),
                          Text('TAP + TO CREATE',
                              style: YamadaTheme.caption
                                  .copyWith(color: YamadaTheme.inkSubtle)),
                        ],
                      ),
                    );
                  }

                  // Sort: CRITICAL first, then STANDARD, then OPTIONAL
                  final sorted = List<HabitModel>.from(habits)..sort((a, b) {
                    const order = {'critical': 0, 'standard': 1, 'optional': 2};
                    final aPri = order[a.priority] ?? 1;
                    final bPri = order[b.priority] ?? 1;
                    if (aPri != bPri) return aPri.compareTo(bPri);
                    return b.currentStreak.compareTo(a.currentStreak);
                  });

                  return AnimationLimiter(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: sorted.length,
                      itemBuilder: (context, index) {
                        final habit = sorted[index];
                        final doneToday = _isDoneToday(habit);

                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 400),
                          child: SlideAnimation(
                            horizontalOffset: 50.0,
                            child: FadeInAnimation(
                              child: _HabitCard(
                                habit: habit,
                                doneToday: doneToday,
                                onCheck: () => _checkHabit(habit),
                                onDelete: () => _deleteHabit(habit.id),
                                onChangePriority: () => _showPriorityPicker(habit),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showHabitForm(context),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  bool _isDoneToday(HabitModel habit) {
    if (habit.lastCompleted == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = DateTime(habit.lastCompleted!.year,
        habit.lastCompleted!.month, habit.lastCompleted!.day);
    return last == today;
  }

  Future<void> _checkHabit(HabitModel habit) async {
    if (_isDoneToday(habit)) return;

    final gamification = GamificationService();

    HapticFeedback.mediumImpact();

    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 1));

    int newStreak = habit.currentStreak;
    if (habit.lastCompleted != null) {
      final lastDay = DateTime(habit.lastCompleted!.year,
          habit.lastCompleted!.month, habit.lastCompleted!.day);
      if (lastDay == yesterday || lastDay == DateTime(now.year, now.month, now.day)) {
        newStreak++;
      } else {
        // Check freeze token
        if (habit.streakFreezeTokens > 0) {
          newStreak++;
          habit.streakFreezeTokens -= 1;
        } else {
          newStreak = 1;
        }
      }
    } else {
      newStreak = 1;
    }

    final bestStreak = newStreak > habit.maxStreak ? newStreak : habit.maxStreak;

    // Award freeze token at 7-day streak milestones (if none held)
    int freezeTokens = habit.streakFreezeTokens;
    if (newStreak > 0 && newStreak % 7 == 0 && freezeTokens == 0) {
      freezeTokens = 1;
    }

    // Haptic milestones
    if (newStreak == 7 || newStreak == 14 || newStreak == 21) {
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 80));
      HapticFeedback.lightImpact();
      HapticFeedback.lightImpact();
    }

    habit.lastCompleted = now;
    habit.currentStreak = newStreak;
    habit.maxStreak = bestStreak;
    habit.streakFreezeTokens = freezeTokens;

    await YamadaDatabase.updateHabit(habit);
    await gamification.awardHabitXp(0);



    if (mounted) {
      String extra = '';
      if (freezeTokens > 0 && habit.streakFreezeTokens == 0) {
        extra = ' 🛡️ FREEZE TOKEN EARNED!';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('DISCIPLINE +1 // +${GamificationService.habitXp} XP$extra',
              style: YamadaTheme.bodyBold.copyWith(color: YamadaTheme.crimson)),
          backgroundColor: YamadaTheme.ink,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(),
        ),
      );
    }
  }

  Future<void> _deleteHabit(String id) async {
    await YamadaDatabase.deleteHabit(id);
  }

  void _showPriorityPicker(HabitModel habit) {
    showModalBottomSheet(
      context: context,
      backgroundColor: YamadaTheme.crimson,
      shape: const RoundedRectangleBorder(),
      builder: (ctx) => _PriorityPickerSheet(
        currentPriority: habit.priority,
        onSelect: (priority) async {
          Navigator.pop(ctx);
          habit.priority = priority;
          await YamadaDatabase.updateHabit(habit);
        },
      ),
    );
  }

  void _showHabitForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: YamadaTheme.crimson,
      shape: const RoundedRectangleBorder(),
      builder: (ctx) => const _HabitFormSheet(),
    );
  }
}

class _HabitCard extends StatelessWidget {
  final HabitModel habit;
  final bool doneToday;
  final VoidCallback onCheck;
  final VoidCallback onDelete;
  final VoidCallback onChangePriority;

  const _HabitCard({
    required this.habit,
    required this.doneToday,
    required this.onCheck,
    required this.onDelete,
    required this.onChangePriority,
  });

  String _priorityBadge(String priority) {
    switch (priority) {
      case 'critical': return '◆ CRIT';
      case 'optional': return '○ OPT';
      default: return '● STD';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOptional = habit.priority == 'optional';

    return GestureDetector(
      onLongPress: onChangePriority,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: YamadaTheme.hardBorder,
          color: doneToday ? YamadaTheme.ink.withValues(alpha: 0.08) : null,
        ),
        padding: const EdgeInsets.all(16),
        child: Opacity(
          opacity: isOptional ? 0.6 : 1.0,
          child: Row(
            children: [
              GestureDetector(
                onTap: onCheck,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: doneToday ? YamadaTheme.ink : null,
                    border: Border.all(color: YamadaTheme.ink, width: 2),
                  ),
                  child: doneToday
                      ? Icon(Icons.check, color: YamadaTheme.crimson, size: 22)
                      : null,
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
                          child: Text(habit.title, style: YamadaTheme.bodyBold),
                        ),
                        const SizedBox(width: 8),
                        // Priority badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          color: YamadaTheme.ink,
                          child: Text(
                            _priorityBadge(habit.priority),
                            style: YamadaTheme.caption.copyWith(
                              color: YamadaTheme.crimson,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          habit.frequency.toUpperCase(),
                          style: YamadaTheme.caption
                              .copyWith(color: YamadaTheme.inkSubtle),
                        ),
                        if (habit.streakFreezeTokens > 0) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.shield, size: 14, color: YamadaTheme.ink),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_fire_department,
                          color: YamadaTheme.ink, size: 18),
                      const SizedBox(width: 4),
                      Text('${habit.currentStreak}',
                          style: YamadaTheme.dataMedium),
                    ],
                  ),
                  Text('BEST: ${habit.maxStreak}',
                      style: YamadaTheme.caption
                          .copyWith(color: YamadaTheme.inkSubtle)),
                ],
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDelete,
                child: Icon(Icons.close, color: YamadaTheme.inkSubtle, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriorityPickerSheet extends StatelessWidget {
  final String currentPriority;
  final ValueChanged<String> onSelect;

  const _PriorityPickerSheet({required this.currentPriority, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('SET PRIORITY', style: YamadaTheme.heading3),
          const SizedBox(height: 16),
          ...['critical', 'standard', 'optional'].map((p) {
            final labels = {'critical': '◆ CRITICAL', 'standard': '● STANDARD', 'optional': '○ OPTIONAL'};
            final descs = {
              'critical': 'Vibration + sound on miss. 3x weight.',
              'standard': 'Normal notification. 1x weight.',
              'optional': 'Dimmed. No escalation. 0.5x weight.',
            };
            final isActive = currentPriority == p;
            return GestureDetector(
              onTap: () => onSelect(p),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isActive ? YamadaTheme.ink : null,
                  border: YamadaTheme.hardBorder,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(labels[p]!,
                        style: YamadaTheme.bodyBold.copyWith(
                          color: isActive ? YamadaTheme.crimson : YamadaTheme.ink,
                        )),
                    const SizedBox(height: 4),
                    Text(descs[p]!,
                        style: YamadaTheme.caption.copyWith(
                          color: isActive
                              ? YamadaTheme.crimson.withValues(alpha: 0.7)
                              : YamadaTheme.inkSubtle,
                        )),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _HabitFormSheet extends StatefulWidget {
  const _HabitFormSheet();

  @override
  State<_HabitFormSheet> createState() => _HabitFormSheetState();
}

class _HabitFormSheetState extends State<_HabitFormSheet> {
  final _titleController = TextEditingController();
  String _frequency = 'daily';
  String _priority = 'standard';

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('NEW HABIT', style: YamadaTheme.heading3),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            style: YamadaTheme.body,
            decoration: const InputDecoration(labelText: 'HABIT NAME'),
          ),
          const SizedBox(height: 16),
          Text('FREQUENCY', style: YamadaTheme.sectionLabel),
          const SizedBox(height: 8),
          Row(
            children: ['daily', 'weekly'].map((freq) {
              final isSelected = _frequency == freq;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _frequency = freq),
                  child: Container(
                    margin: EdgeInsets.only(right: freq == 'daily' ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? YamadaTheme.ink : null,
                      border: YamadaTheme.hardBorder,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      freq.toUpperCase(),
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
          Text('PRIORITY', style: YamadaTheme.sectionLabel),
          const SizedBox(height: 8),
          Row(
            children: ['critical', 'standard', 'optional'].map((pri) {
              final isSelected = _priority == pri;
              final labels = {'critical': '◆ CRIT', 'standard': '● STD', 'optional': '○ OPT'};
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _priority = pri),
                  child: Container(
                    margin: EdgeInsets.only(right: pri != 'optional' ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? YamadaTheme.ink : null,
                      border: YamadaTheme.hardBorder,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      labels[pri]!,
                      style: YamadaTheme.caption.copyWith(
                        color: isSelected ? YamadaTheme.crimson : YamadaTheme.ink,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _save,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: YamadaTheme.ink,
              alignment: Alignment.center,
              child: Text(
                'DEPLOY HABIT',
                style: YamadaTheme.bodyBold.copyWith(
                    color: YamadaTheme.crimson, letterSpacing: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) return;
    
    final newHabit = HabitModel(
      id: const Uuid().v4(),
      title: _titleController.text.trim(),
      frequency: _frequency,
      priority: _priority,
      createdAt: DateTime.now(),
    );
    
    await YamadaDatabase.addHabit(newHabit);
    if (mounted) Navigator.pop(context);
  }
}
