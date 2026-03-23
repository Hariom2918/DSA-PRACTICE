import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import '../database/hive_database.dart';
import 'notification_service.dart';
import 'intelligence_service.dart';

/// Background task callback — runs outside of main isolate.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      await YamadaDatabase.init();
      final notificationService = NotificationService();
      await notificationService.initialize();
      final intelligence = IntelligenceService();

      switch (taskName) {
        case 'com.yamada.taskEscalation':
          await notificationService.checkAndEscalateTasks();
          break;

        case 'com.yamada.habitEscalation':
          await notificationService.checkAndEscalateHabits();
          break;

        case 'com.yamada.intelligenceSync':
          await intelligence.autoRescheduleIgnoredTasks();
          await intelligence.escalateMissedHabits();
          break;

        case 'com.yamada.dailyReset':
          // await db.archiveOldTasks(); 
          // Hive archiving handles separately
          break;

        case 'com.yamada.morningBriefing':
          await notificationService.sendDailyBriefing();
          break;

        case 'com.yamada.eveningDebrief':
          await notificationService.sendDailyDebrief();
          break;
      }

      return true;
    } catch (e) {
      debugPrint('Background task error ($taskName): $e');
      return false;
    }
  });
}

/// Background service — registers periodic tasks.
class BackgroundService {
  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher);

    // Task escalation check every 1 hour
    await Workmanager().registerPeriodicTask(
      'yamada-task-escalation',
      'com.yamada.taskEscalation',
      frequency: const Duration(hours: 1),
      constraints: Constraints(networkType: NetworkType.notRequired),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );

    // Habit escalation check every 6 hours
    await Workmanager().registerPeriodicTask(
      'yamada-habit-escalation',
      'com.yamada.habitEscalation',
      frequency: const Duration(hours: 6),
      constraints: Constraints(networkType: NetworkType.notRequired),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );

    // Intelligence sync every 12 hours
    await Workmanager().registerPeriodicTask(
      'yamada-intelligence-sync',
      'com.yamada.intelligenceSync',
      frequency: const Duration(hours: 12),
      constraints: Constraints(networkType: NetworkType.notRequired),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );

    // Daily reset every 24 hours
    await Workmanager().registerPeriodicTask(
      'yamada-daily-reset',
      'com.yamada.dailyReset',
      frequency: const Duration(hours: 24),
      constraints: Constraints(networkType: NetworkType.notRequired),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );

    // Morning briefing every 24 hours
    await Workmanager().registerPeriodicTask(
      'yamada-morning-briefing',
      'com.yamada.morningBriefing',
      frequency: const Duration(hours: 24),
      initialDelay: _delayUntilNextMorning(),
      constraints: Constraints(networkType: NetworkType.notRequired),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );

    // Evening debrief every 24 hours
    await Workmanager().registerPeriodicTask(
      'yamada-evening-debrief',
      'com.yamada.eveningDebrief',
      frequency: const Duration(hours: 24),
      initialDelay: _delayUntilEvening(),
      constraints: Constraints(networkType: NetworkType.notRequired),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );
  }

  static Duration _delayUntilNextMorning() {
    final now = DateTime.now();
    var morning = DateTime(now.year, now.month, now.day, 7, 0);
    if (morning.isBefore(now)) {
      morning = morning.add(const Duration(days: 1));
    }
    return morning.difference(now);
  }

  static Duration _delayUntilEvening() {
    final now = DateTime.now();
    var evening = DateTime(now.year, now.month, now.day, 22, 0);
    if (evening.isBefore(now)) {
      evening = evening.add(const Duration(days: 1));
    }
    return evening.difference(now);
  }

  /// Cancel all background tasks
  static Future<void> cancelAll() async {
    await Workmanager().cancelAll();
  }
}
