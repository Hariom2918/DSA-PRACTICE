import '../database/hive_database.dart';
import '../models/user_settings_model.dart';
import '../models/task_model.dart';

/// Gamification engine — XP, levels, streaks, identity score.
class GamificationService {
  GamificationService();

  // ── XP Constants ──────────────────────────────────────────
  static const int habitXp = 15;
  static const int focusXpPerMinute = 2;
  static const Map<int, int> taskXpByPriority = {
    1: 10,
    2: 15,
    3: 25,
    4: 40,
  };

  // ── Level System ──────────────────────────────────────────
  static int xpForLevel(int level) => (level * level * 50);

  static int levelFromXp(int xp) {
    int level = 1;
    while (xpForLevel(level + 1) <= xp) {
      level++;
    }
    return level;
  }

  static double levelProgress(int xp) {
    final level = levelFromXp(xp);
    final currentLevelXp = xpForLevel(level);
    final nextLevelXp = xpForLevel(level + 1);
    return (xp - currentLevelXp) / (nextLevelXp - currentLevelXp);
  }

  // ── XP Operations ─────────────────────────────────────────
  Future<int> getTotalXp() async {
    return YamadaDatabase.getUserSettings().totalXp;
  }

  Future<void> _addXp(int amount) async {
    final settings = YamadaDatabase.getUserSettings();
    settings.totalXp += amount;
    settings.level = levelFromXp(settings.totalXp);
    await YamadaDatabase.updateUserSettings(settings);
  }

  Future<int> awardTaskXp(int taskId, String priority) async {
    // Map string priority to int value for legacy map compatibility
    int priorityInt = 2; // standard
    if (priority == 'critical') priorityInt = 4;
    if (priority == 'optional') priorityInt = 1;

    final xp = taskXpByPriority[priorityInt] ?? 10;
    await _addXp(xp);
    return xp;
  }

  Future<int> awardHabitXp(int habitId) async {
    await _addXp(habitXp);
    return habitXp;
  }

  Future<int> awardFocusXp(int minutes) async {
    final xp = focusXpPerMinute * minutes;
    await _addXp(xp);
    return xp;
  }

  // ── Streak Calculation ────────────────────────────────────
  Future<int> calculateStreak() async {
    final now = DateTime.now();
    int streak = 0;
    final allTasks = YamadaDatabase.getAllTasks();
    final allHabits = YamadaDatabase.getAllHabits();
    final allFocus = YamadaDatabase.getAllFocusSessions();

    for (int i = 0; i < 365; i++) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      
      final tasksDone = allTasks.where((t) => t.isCompleted && t.dueDate != null && t.dueDate!.year == date.year && t.dueDate!.month == date.month && t.dueDate!.day == date.day).length;
      final habitsDone = allHabits.where((h) => h.lastCompleted != null && h.lastCompleted!.year == date.year && h.lastCompleted!.month == date.month && h.lastCompleted!.day == date.day).length;
      final focusDone = allFocus.where((f) => f.completed && f.startTime.year == date.year && f.startTime.month == date.month && f.startTime.day == date.day).length;

      if (tasksDone == 0 && habitsDone == 0 && focusDone == 0) {
        // Allow today to be empty (day not over yet)
        if (i == 0) continue;
        break;
      }
      streak++;
    }
    return streak;
  }

  // ── Identity Score ────────────────────────────────────────
  /// Weighted identity score out of 10.
  /// Factors: task completion rate, habit consistency (weighted by priority), streak, focus minutes
  Future<double> calculateIdentityScore() async {
    final now = DateTime.now();
    final weekAgo = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7));
    
    final allTasks = YamadaDatabase.getAllTasks();
    final allFocus = YamadaDatabase.getAllFocusSessions();

    final recentTasksCompleted = allTasks.where((t) => t.isCompleted && t.dueDate != null && t.dueDate!.isAfter(weekAgo)).length;
    final recentFocusMinutes = allFocus.where((f) => f.completed && f.startTime.isAfter(weekAgo)).fold(0, (sum, f) => sum + f.durationMinutes);

    // Task completion component (0-3 points)
    final taskScore = (recentTasksCompleted / 5).clamp(0.0, 3.0); // 5 tasks per day target

    // Habit consistency component with priority weighting (0-3 points)
    final habits = YamadaDatabase.getAllHabits();
    double habitScore = 0.0;
    if (habits.isNotEmpty) {
      double totalWeight = 0;
      double completedWeight = 0;

      for (final habit in habits) {
        final weight = _priorityWeight(habit.priority);
        totalWeight += weight;
        if (habit.lastCompleted != null) {
          final daysSince = now.difference(habit.lastCompleted!).inDays;
          if (daysSince <= 1) {
            completedWeight += weight;
          } else if (daysSince <= 3) {
            completedWeight += weight * 0.5;
          }
        }
      }

      if (totalWeight > 0) {
        habitScore = (completedWeight / totalWeight * 3.0).clamp(0.0, 3.0);
      }
    }

    // Streak bonus (0-2 points)
    final streak = await calculateStreak();
    final streakScore = (streak / 7).clamp(0.0, 2.0);

    // Focus component (0-2 points)
    final focusScore = (recentFocusMinutes / 180).clamp(0.0, 2.0); // 180min/week target

    return (taskScore + habitScore + streakScore + focusScore).clamp(0.0, 10.0);
  }

  double _priorityWeight(String priority) {
    switch (priority) {
      case 'critical': return 3.0;
      case 'optional': return 0.5;
      default: return 1.0; // standard
    }
  }
}
