import 'package:hive/hive.dart';

part 'habit_model.g.dart';

@HiveType(typeId: 1)
class HabitModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  String frequency; // 'daily', 'weekly'

  @HiveField(4)
  int currentStreak;

  @HiveField(5)
  int maxStreak;

  @HiveField(6)
  DateTime? lastCompleted;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  String priority; // 'critical', 'standard', 'optional'

  @HiveField(9)
  int streakFreezeTokens;

  HabitModel({
    required this.id,
    required this.title,
    this.description,
    this.frequency = 'daily',
    this.currentStreak = 0,
    this.maxStreak = 0,
    this.lastCompleted,
    required this.createdAt,
    this.priority = 'standard',
    this.streakFreezeTokens = 0,
  });
}
