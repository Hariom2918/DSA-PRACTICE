import 'package:hive/hive.dart';

part 'focus_session_model.g.dart';

@HiveType(typeId: 3)
class FocusSessionModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime startTime;

  @HiveField(2)
  int durationMinutes;

  @HiveField(3)
  bool completed;

  @HiveField(4)
  String? tags;

  FocusSessionModel({
    required this.id,
    required this.startTime,
    required this.durationMinutes,
    this.completed = false,
    this.tags,
  });
}
