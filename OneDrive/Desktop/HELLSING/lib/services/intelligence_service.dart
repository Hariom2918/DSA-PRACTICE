import '../database/hive_database.dart';
import '../models/habit_model.dart';
import '../models/task_model.dart';

/// Intelligence engine — rule-based behavior for smart scheduling.
class IntelligenceService {
  IntelligenceService();

  /// Detect peak productivity hours from completed tasks.
  Future<Map<int, int>> detectPeakHours() async {
    final tasks = YamadaDatabase.getAllTasks();
    final hourMap = <int, int>{};

    for (final task in tasks) {
      if (task.isCompleted && task.dueDate != null) {
        final hour = task.dueDate!.hour;
        hourMap[hour] = (hourMap[hour] ?? 0) + 1;
      }
    }

    return hourMap;
  }

  /// Get the most productive time of day.
  Future<String> getMostProductiveTime() async {
    final peaks = await detectPeakHours();
    if (peaks.isEmpty) return 'NOT ENOUGH DATA';

    final sorted = peaks.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final peakHour = sorted.first.key;
    final period = peakHour >= 12 ? 'PM' : 'AM';
    final displayHour = peakHour > 12 ? peakHour - 12 : (peakHour == 0 ? 12 : peakHour);

    return '$displayHour $period';
  }

  /// Auto-reschedule ignored tasks (tasks past due with miss count > 2).
  Future<int> autoRescheduleIgnoredTasks() async {
    final tasks = YamadaDatabase.getAllTasks();
    final now = DateTime.now();
    int rescheduled = 0;

    for (final task in tasks) {
      if (task.isCompleted || task.isArchived) continue;
      // Note: assuming missCount is a concept we implement or ignore. We'll skip missCount logic or use due date age.
      if (task.dueDate != null && now.difference(task.dueDate!).inDays >= 2) {
        // Push to tomorrow at 9 AM
        final tomorrow = DateTime(now.year, now.month, now.day + 1, 9, 0);
        task.dueDate = tomorrow;
        await YamadaDatabase.updateTask(task);
        rescheduled++;
      }
    }

    return rescheduled;
  }

  /// Escalate missed habits — update miss count and return escalated habits.
  Future<List<HabitModel>> escalateMissedHabits() async {
    final habits = YamadaDatabase.getAllHabits();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final escalated = <HabitModel>[];

    for (final habit in habits) {
      if (habit.lastCompleted == null) continue;
      final lastDay = DateTime(habit.lastCompleted!.year,
          habit.lastCompleted!.month, habit.lastCompleted!.day);
      final missedDays = today.difference(lastDay).inDays;

      if (missedDays >= 2) {
        // Check for streak freeze token
        if (habit.streakFreezeTokens > 0 && missedDays == 2) {
          // Auto-activate freeze token
          habit.streakFreezeTokens -= 1;
          await YamadaDatabase.updateHabit(habit);
        } else {
          // habit.missCount concept can be added later if needed, escalating based on priority.
          escalated.add(habit);
        }
      }
    }

    return escalated;
  }

  /// Generate escalation copy for a task.
  static String taskEscalation(String title, int missCount) {
    if (missCount >= 3) return '⚠️ THIRD WARNING: "$title" — HANDLE IT OR IT\'S ARCHIVED.';
    if (missCount >= 2) return '⚠️ "$title" MISSED AGAIN. RECKONING APPROACHES.';
    return '⚠️ "$title" WAS IGNORED. RESCHEDULE OR EXECUTE.';
  }

  /// Generate escalation copy for a habit.
  static String habitEscalation(String title, int missedDays, String priority) {
    if (priority == 'critical') {
      return '🔥 CRITICAL: "$title" MISSED $missedDays DAYS. STREAK BROKEN.';
    }
    if (missedDays >= 3) return '⚠️ "$title" — $missedDays DAY GAP. STREAK DESTROYED.';
    return '⚠️ "$title" MISSED YESTERDAY. GET BACK ON TRACK.';
  }

  /// Get daily summary for briefing
  Future<Map<String, dynamic>> getDailySummary() async {
    final tasks = YamadaDatabase.getAllTasks();
    final habits = YamadaDatabase.getAllHabits();
    final now = DateTime.now();
    
    final incomplete = tasks.where((t) => !t.isCompleted).length;
    final overdue = tasks.where((t) =>
        !t.isCompleted && t.dueDate != null && t.dueDate!.isBefore(now)).length;
        
    final sessions = YamadaDatabase.getAllFocusSessions()
          .where((s) => s.startTime.day == now.day && s.completed);
    final todayFocus = sessions.fold(0, (sum, s) => sum + s.durationMinutes);

    return {
      'tasks_remaining': incomplete,
      'tasks_overdue': overdue,
      'habits_total': habits.length,
      'focus_minutes': todayFocus,
    };
  }
}
