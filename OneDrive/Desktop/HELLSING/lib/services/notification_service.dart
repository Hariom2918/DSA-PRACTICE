import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../database/hive_database.dart';
import '../models/task_model.dart';
import '../models/habit_model.dart';

/// Notification service — handles all local notifications.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  /// Notification channel IDs 
  static const String _taskChannelId = 'yamada_tasks';
  static const String _taskChannelName = 'YAMADA Tasks';
  static const String _habitChannelId = 'yamada_habits';
  static const String _habitChannelName = 'YAMADA Habits';
  static const String _briefingChannelId = 'yamada_briefing';
  static const String _briefingChannelName = 'YAMADA Briefing';

  NotificationService();

  /// Initialize notification plugin and create channels
  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create Android notification channels explicitly
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _taskChannelId,
            _taskChannelName,
            description: 'Task reminders and escalations',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _habitChannelId,
            _habitChannelName,
            description: 'Habit reminders',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _briefingChannelId,
            _briefingChannelName,
            description: 'Daily briefing and debrief',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );
      }
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap — could navigate to specific screen
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Request notification permissions (Android 13+, iOS)
  Future<void> requestPermissions() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.requestExactAlarmsPermission();
    } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  /// Schedule task multi-reminders
  Future<void> scheduleTaskReminders(TaskModel task) async {
    if (task.dueDate == null) return;
    if (task.notificationId == null) return;
    
    // Aggressive messages
    final messages = [
      "Time to act. Not tomorrow.",
      "You planned this. Now execute.",
      "Discipline > motivation.",
      "Execute.",
      "No excuses."
    ];
    final randomMessage = messages[Random().nextInt(messages.length)];

    final idBase = task.notificationId!;
    
    // Exact time
    await _scheduleExact(
      idBase,
      'MISSION DUE:',
      task.title,
      task.dueDate!,
      'task:${task.id}'
    );

    // 1 hour before
    final oneHourBefore = task.dueDate!.subtract(const Duration(hours: 1));
    if (oneHourBefore.isAfter(DateTime.now())) {
      await _scheduleExact(
        idBase + 1,
        'UPCOMING IN 1 HOUR',
        '"${task.title}" — $randomMessage',
        oneHourBefore,
        'task:${task.id}'
      );
    }

    // 1 day before
    final oneDayBefore = task.dueDate!.subtract(const Duration(days: 1));
    if (oneDayBefore.isAfter(DateTime.now())) {
      await _scheduleExact(
        idBase + 2,
        'TOMORROW',
        '"${task.title}" starts tomorrow. Prepare yourself.',
        oneDayBefore,
        'task:${task.id}'
      );
    }
  }

  Future<void> _scheduleExact(int id, String title, String body, DateTime when, String payload) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(when, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _taskChannelId,
          _taskChannelName,
          importance: Importance.max,
          priority: Priority.max,
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<void> cancelTaskReminders(int notificationId) async {
    await _plugin.cancel(notificationId);
    await _plugin.cancel(notificationId + 1);
    await _plugin.cancel(notificationId + 2);
  }

  /// Schedule a recurring habit reminder
  Future<void> scheduleHabitReminder(int habitId, String title, TimeOfDay time) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      10000 + habitId,
      'HABIT CHECK',
      title,
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _habitChannelId,
          _habitChannelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'habit:$habitId',
    );
  }

  /// Send daily war briefing
  Future<void> sendDailyBriefing() async {
    final tasks = YamadaDatabase.getAllTasks();
    final habits = YamadaDatabase.getAllHabits();
    final incomplete = tasks.where((t) => !t.isCompleted).length;

    await _plugin.show(
      99001,
      'YAMADA — WAR BRIEFING',
      'TODAY\'S MISSION: $incomplete TASKS · ${habits.length} HABITS',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _briefingChannelId,
          _briefingChannelName,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(
            'TODAY\'S MISSION: $incomplete TASKS · ${habits.length} HABITS · FOCUS GOAL: 3H',
          ),
        ),
      ),
      payload: 'briefing',
    );
  }

  /// Send end-of-day debrief
  Future<void> sendDailyDebrief() async {
    final habits = YamadaDatabase.getAllHabits();
    final tasks = YamadaDatabase.getAllTasks();
    final completedTasks = tasks.where((t) => t.isCompleted && t.dueDate != null && t.dueDate!.day == DateTime.now().day).length;

    String body = 'TASKS: $completedTasks · HABITS: ${habits.length}';

    await _plugin.show(
      99002,
      'YAMADA — DEBRIEF',
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _briefingChannelId,
          _briefingChannelName,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(body),
        ),
      ),
      payload: 'debrief',
    );
  }

  /// Check for missed tasks and escalate
  Future<void> checkAndEscalateTasks() async {
    final tasks = YamadaDatabase.getAllTasks();
    final now = DateTime.now();

    for (final task in tasks) {
      if (task.isCompleted || task.isArchived) continue;
      if (task.dueDate == null) continue;
      if (task.dueDate!.isBefore(now)) {
        // Missed — send escalation
        await _plugin.show(
          20000 + task.id.hashCode,
          'MISSED MISSION',
          '⚠️ "${task.title}" IS OVERDUE. HANDLE IT.',
          NotificationDetails(
            android: AndroidNotificationDetails(
              _taskChannelId,
              _taskChannelName,
              importance: Importance.max,
              priority: Priority.max,
            ),
          ),
          payload: 'task:${task.id.hashCode}',
        );

        // Optional: you can add a missCount field to TaskModel later
      }
    }
  }

  /// Check for missed habits
  Future<void> checkAndEscalateHabits() async {
    final habits = YamadaDatabase.getAllHabits();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final habit in habits) {
      if (habit.lastCompleted == null) continue;
      final lastDay = DateTime(habit.lastCompleted!.year,
          habit.lastCompleted!.month, habit.lastCompleted!.day);
      final missedDays = today.difference(lastDay).inDays;

      if (missedDays >= 2) {
        // Send escalation based on priority
        final importance = habit.priority == 'critical'
            ? Importance.max
            : Importance.high;

        await _plugin.show(
          30000 + habit.id.hashCode,
          habit.priority == 'critical'
              ? '🔥 CRITICAL HABIT MISSED'
              : 'HABIT MISSED',
          '"${habit.title}" — $missedDays DAYS MISSED. STREAK IN DANGER.',
          NotificationDetails(
            android: AndroidNotificationDetails(
              _habitChannelId,
              _habitChannelName,
              importance: importance,
              priority: Priority.max,
              enableVibration: habit.priority == 'critical',
              playSound: habit.priority == 'critical',
            ),
          ),
          payload: 'habit:${habit.id.hashCode}',
        );

        // db.updateHabit logic
      }
    }
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
