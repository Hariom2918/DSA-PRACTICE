import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../database/hive_database.dart';
import '../models/task_model.dart';
import '../models/habit_model.dart';
import 'notification_service.dart';
import 'gamification_service.dart';

/// Command result with action type for structured responses.
enum CommandAction { none, navigateToFocus, showStreak, showStats, error }

class CommandResult {
  final String message;
  final CommandAction action;

  CommandResult(this.message, {this.action = CommandAction.none});
}

/// Command bar — natural language input parser.
class CommandService {
  final GamificationService gamification;

  CommandService(this.gamification);

  /// Parse and execute a natural language command.
  Future<CommandResult> execute(String input) async {
    final cmd = input.trim().toLowerCase();

    // ── Add Task
    if (cmd.startsWith('add task') || cmd.startsWith('new task') || cmd.startsWith('create task')) {
      return CommandResult(await _addTask(input));
    }

    // ── Add Habit
    if (cmd.startsWith('add habit') || cmd.startsWith('new habit') || cmd.startsWith('create habit')) {
      return CommandResult(await _addHabit(input));
    }

    // ── Reschedule
    if (cmd.startsWith('reschedule') || cmd.startsWith('move')) {
      return CommandResult(await _reschedule(input));
    }

    // ── Complete
    if (cmd.startsWith('complete') || cmd.startsWith('done') || cmd.startsWith('finish')) {
      return CommandResult(await _completeTask(input));
    }

    // ── Snooze
    if (cmd.startsWith('snooze')) {
      return CommandResult(await _snoozeTask(input));
    }

    // ── Start Focus
    if (cmd.contains('start focus') || cmd.contains('focus mode') || cmd == 'focus') {
      return CommandResult('FOCUS MODE ACTIVATED.', action: CommandAction.navigateToFocus);
    }

    // ── How am I doing
    if (cmd.contains('how am i doing') || cmd.contains('how am i') || cmd.contains('how\'s it going')) {
      return CommandResult(await _quickStats(), action: CommandAction.showStats);
    }

    // ── Show Stats
    if (cmd.contains('streak')) {
      final streak = await gamification.calculateStreak();
      return CommandResult(
        'STREAK: $streak DAYS. ${streak > 7 ? "LOCKED IN." : "KEEP PUSHING."}',
        action: CommandAction.showStreak,
      );
    }
    if (cmd.contains('level')) {
      final xp = await gamification.getTotalXp();
      final level = GamificationService.levelFromXp(xp);
      return CommandResult('LEVEL $level // $xp XP TOTAL.');
    }
    if (cmd.contains('xp') || cmd.contains('experience')) {
      final xp = await gamification.getTotalXp();
      return CommandResult('TOTAL XP: $xp. NEXT LEVEL AT ${GamificationService.xpForLevel(GamificationService.levelFromXp(xp) + 1)} XP.');
    }
    if (cmd.contains('score') || cmd.contains('identity')) {
      final score = await gamification.calculateIdentityScore();
      return CommandResult('IDENTITY SCORE: ${score.toStringAsFixed(1)}/10. ${score >= 7 ? "ELITE." : score >= 5 ? "IMPROVING." : "WEAK. FIX IT."}');
    }
    if (cmd.contains('status') || cmd.contains('report') || cmd.contains('summary')) {
      return CommandResult(await _getStatusReport());
    }

    // ── List
    if (cmd.contains('list task') || cmd.contains('show task') || cmd.contains('my task')) {
      final tasks = YamadaDatabase.getAllTasks();
      final incomplete = tasks.where((t) => !t.isCompleted).toList();
      if (incomplete.isEmpty) return CommandResult('NO ACTIVE MISSIONS.');
      final lines = incomplete.asMap().entries.map((e) => '${e.key + 1}. ${e.value.title}').join('\n');
      return CommandResult('ACTIVE MISSIONS:\n$lines');
    }

    // ── Delete
    if (cmd.startsWith('delete') || cmd.startsWith('remove')) {
      return CommandResult(await _deleteTask(input));
    }

    // ── Help
    if (cmd.contains('help') || cmd.contains('commands')) {
      return CommandResult(
        'COMMANDS:\n'
        '• add task [name] at [time]\n'
        '• add habit [name]\n'
        '• reschedule [task] to [day/time]\n'
        '• complete [task name]\n'
        '• snooze [task name]\n'
        '• start focus\n'
        '• show streak / level / xp / score\n'
        '• how am i doing\n'
        '• list tasks\n'
        '• delete [task name]\n'
        '• status / report',
      );
    }

    return CommandResult(
      'COMMAND NOT RECOGNIZED. TYPE "HELP" FOR LIST.',
      action: CommandAction.error,
    );
  }

  Future<String> _quickStats() async {
    final now = DateTime.now();
    final allTasks = YamadaDatabase.getAllTasks();
    final tasksToday = allTasks.where((t) => t.isCompleted && t.dueDate != null && t.dueDate!.day == now.day).length;
    final streak = await gamification.calculateStreak();
    final score = await gamification.calculateIdentityScore();

    return 'TODAY: $tasksToday TASKS DONE · STREAK: $streak DAYS · IDENTITY: ${score.toStringAsFixed(1)}/10';
  }

  Future<String> _snoozeTask(String input) async {
    final query = input.replaceAll(RegExp(r'^snooze\s*', caseSensitive: false), '').trim();
    if (query.isEmpty) return 'SPECIFY WHICH TASK TO SNOOZE.';

    final tasks = YamadaDatabase.getAllTasks();
    final match = tasks.where((t) =>
        t.title.toLowerCase().contains(query.toLowerCase()) && !t.isCompleted).toList();

    if (match.isEmpty) return 'NO ACTIVE MISSION MATCHING "$query".';

    final task = match.first;
    final newDue = (task.dueDate ?? DateTime.now()).add(const Duration(minutes: 30));
    
    task.dueDate = newDue;
    await YamadaDatabase.updateTask(task);

    // Update notifications
    await NotificationService().scheduleTaskReminders(task);

    return 'SNOOZED: "${task.title}" → ${DateFormat('HH:mm').format(newDue)}. 30 MIN EXTENSION.';
  }

  Future<String> _addTask(String input) async {
    String title;
    DateTime? dueDate;
    String priority = 'standard';

    final colonIdx = input.indexOf(':');
    if (colonIdx != -1 && colonIdx < input.length - 1) {
      title = input.substring(colonIdx + 1).trim();
    } else {
      title = input.replaceAll(RegExp(r'^(add|new|create)\s+task\s*', caseSensitive: false), '').trim();
    }

    final atMatch = RegExp(r'\bat\s+(\d{1,2})\s*(am|pm|AM|PM)?\b').firstMatch(title);
    if (atMatch != null) {
      int hour = int.parse(atMatch.group(1)!);
      final ampm = atMatch.group(2)?.toLowerCase();
      if (ampm == 'pm' && hour < 12) hour += 12;
      if (ampm == 'am' && hour == 12) hour = 0;

      final now = DateTime.now();
      dueDate = DateTime(now.year, now.month, now.day, hour, 0);
      if (dueDate.isBefore(now)) {
        dueDate = dueDate.add(const Duration(days: 1));
      }
      title = title.replaceAll(atMatch.group(0)!, '').trim();
    }

    if (title.toLowerCase().contains('urgent') || title.toLowerCase().contains('critical')) {
      priority = 'critical';
      title = title.replaceAll(RegExp(r'\b(urgent|critical)\b', caseSensitive: false), '').trim();
    } else if (title.toLowerCase().contains('important') || title.toLowerCase().contains('high')) {
      priority = 'high';
      title = title.replaceAll(RegExp(r'\b(important|high priority|high)\b', caseSensitive: false), '').trim();
    } else if (title.toLowerCase().contains('optional') || title.toLowerCase().contains('low')) {
      priority = 'optional';
    }

    if (title.isEmpty) return 'SPECIFY A TASK NAME.';

    // Set notification ID generated by time
    final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000 % 100000;

    final newTask = TaskModel(
      id: const Uuid().v4(),
      title: title,
      dueDate: dueDate,
      priority: priority,
      createdAt: DateTime.now(),
      notificationId: notificationId,
    );

    await YamadaDatabase.addTask(newTask);
    if (dueDate != null) {
      await NotificationService().scheduleTaskReminders(newTask);
    }

    final xp = 10; // Base creation estimate

    final dueLine = dueDate != null
        ? ' // DUE: ${DateFormat('dd MMM HH:mm').format(dueDate)}'
        : '';
    return 'MISSION DEPLOYED: "$title"$dueLine // +$xp XP ON COMPLETION.';
  }

  Future<String> _addHabit(String input) async {
    String title;
    String frequencyStr = 'daily';

    final colonIdx = input.indexOf(':');
    if (colonIdx != -1 && colonIdx < input.length - 1) {
      title = input.substring(colonIdx + 1).trim();
    } else {
      title = input.replaceAll(RegExp(r'^(add|new|create)\s+habit\s*', caseSensitive: false), '').trim();
    }

    int frequency = 7;
    if (title.toLowerCase().contains('weekly')) {
      frequencyStr = 'weekly';
      frequency = 1;
      title = title.replaceAll(RegExp(r'\bweekly\b', caseSensitive: false), '').trim();
    } else {
      title = title.replaceAll(RegExp(r'\bdaily\b', caseSensitive: false), '').trim();
    }

    if (title.isEmpty) return 'SPECIFY A HABIT NAME.';

    final newHabit = HabitModel(
      id: const Uuid().v4(),
      title: title,
      frequency: frequencyStr,
      createdAt: DateTime.now(),
    );

    await YamadaDatabase.addHabit(newHabit);

    return 'HABIT DEPLOYED: "$title" ($frequencyStr). STREAK STARTS NOW.';
  }

  Future<String> _reschedule(String input) async {
    final parts = input.toLowerCase().split(' to ');
    if (parts.length < 2) return 'FORMAT: reschedule [task] to [day/time]';

    final taskQuery = parts[0].replaceAll(RegExp(r'^(reschedule|move)\s*', caseSensitive: false), '').trim();
    final target = parts[1].trim();

    final tasks = YamadaDatabase.getAllTasks();
    final match = tasks.where((t) =>
        t.title.toLowerCase().contains(taskQuery) && !t.isCompleted).toList();

    if (match.isEmpty) return 'NO MISSION FOUND MATCHING "$taskQuery".';

    final task = match.first;
    DateTime? newDue;

    final dayNames = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final shortDayNames = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

    for (int i = 0; i < dayNames.length; i++) {
      if (target.contains(dayNames[i]) || target.contains(shortDayNames[i])) {
        final now = DateTime.now();
        int daysAhead = (i + 1 - now.weekday) % 7;
        if (daysAhead == 0) daysAhead = 7;
        newDue = DateTime(now.year, now.month, now.day + daysAhead, 9, 0);
        break;
      }
    }

    if (target.contains('tomorrow')) {
      final now = DateTime.now();
      newDue = DateTime(now.year, now.month, now.day + 1, 9, 0);
    }

    final timeMatch = RegExp(r'(\d{1,2})\s*(am|pm|AM|PM)?').firstMatch(target);
    if (timeMatch != null && newDue == null) {
      int hour = int.parse(timeMatch.group(1)!);
      final ampm = timeMatch.group(2)?.toLowerCase();
      if (ampm == 'pm' && hour < 12) hour += 12;
      if (ampm == 'am' && hour == 12) hour = 0;

      final now = DateTime.now();
      newDue = DateTime(now.year, now.month, now.day, hour, 0);
      if (newDue.isBefore(now)) newDue = newDue.add(const Duration(days: 1));
    }

    if (newDue == null) return 'COULD NOT PARSE TARGET TIME. USE: "friday", "tomorrow", "5 PM".';

    task.dueDate = newDue;
    await YamadaDatabase.updateTask(task);
    await NotificationService().scheduleTaskReminders(task);

    return 'RESCHEDULED: "${task.title}" → ${DateFormat('EEEE dd MMM, HH:mm').format(newDue)}.';
  }

  Future<String> _completeTask(String input) async {
    final query = input.replaceAll(RegExp(r'^(complete|done|finish)\s*', caseSensitive: false), '').trim();

    final tasks = YamadaDatabase.getAllTasks();
    final match = tasks.where((t) =>
        t.title.toLowerCase().contains(query.toLowerCase()) && !t.isCompleted).toList();

    if (match.isEmpty) return 'NO ACTIVE MISSION MATCHING "$query".';

    final task = match.first;
    task.isCompleted = true;
    await YamadaDatabase.updateTask(task);
    
    // Clear notifications since it's done
    if (task.notificationId != null) {
      await NotificationService().cancelTaskReminders(task.notificationId!);
    }
    
    final xp = await gamification.awardTaskXp(0, task.priority);

    return 'MISSION COMPLETE: "${task.title}" // +$xp XP EARNED.';
  }

  Future<String> _deleteTask(String input) async {
    final query = input.replaceAll(RegExp(r'^(delete|remove)\s*(task)?\s*', caseSensitive: false), '').trim();

    final tasks = YamadaDatabase.getAllTasks();
    final match = tasks.where((t) =>
        t.title.toLowerCase().contains(query.toLowerCase())).toList();

    if (match.isEmpty) return 'NO MISSION FOUND MATCHING "$query".';

    final task = match.first;
    if (task.notificationId != null) {
      await NotificationService().cancelTaskReminders(task.notificationId!);
    }
    
    await YamadaDatabase.deleteTask(task.id);
    return 'DELETED: "${task.title}". GONE.';
  }

  Future<String> _getStatusReport() async {
    final xp = await gamification.getTotalXp();
    final level = GamificationService.levelFromXp(xp);
    final streak = await gamification.calculateStreak();
    final score = await gamification.calculateIdentityScore();
    final tasks = YamadaDatabase.getAllTasks();
    final incomplete = tasks.where((t) => !t.isCompleted).length;
    final habits = YamadaDatabase.getAllHabits();
    final activeStreaks = habits.where((h) => h.currentStreak > 0).length;

    return '═══ YAMADA STATUS ═══\n'
        'LEVEL $level // $xp XP\n'
        'STREAK: $streak DAYS\n'
        'IDENTITY: ${score.toStringAsFixed(1)}/10\n'
        'ACTIVE MISSIONS: $incomplete\n'
        'HABIT STREAKS: $activeStreaks/${habits.length}\n'
        '═══════════════════════';
  }
}
