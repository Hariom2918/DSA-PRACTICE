import 'package:hive/hive.dart';

part 'task_model.g.dart';

@HiveType(typeId: 0)
class TaskModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  DateTime? dueDate;

  @HiveField(4)
  bool isCompleted;

  @HiveField(5)
  int? notificationId;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  bool isArchived;

  @HiveField(8)
  String priority; // 'critical', 'standard', 'optional'

  @HiveField(9)
  List<String> tags;

  TaskModel({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.isCompleted = false,
    this.notificationId,
    required this.createdAt,
    this.isArchived = false,
    this.priority = 'standard',
    this.tags = const [],
  });
}
