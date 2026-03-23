import 'package:hive/hive.dart';

part 'user_settings_model.g.dart';

@HiveType(typeId: 4)
class UserSettingsModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String wakeTime; // HH:mm format

  @HiveField(3)
  String sleepTime; // HH:mm format

  @HiveField(4)
  int identityScore;

  @HiveField(5)
  int level;
  
  @HiveField(6)
  int totalXp;

  @HiveField(7)
  bool onboardingDone;

  @HiveField(8)
  int focusCustomDuration;

  @HiveField(9)
  String soundMode; // SILENCE, STATIC, FORGE

  UserSettingsModel({
    this.id = 'default',
    this.name = 'COMMANDER',
    this.wakeTime = '06:00',
    this.sleepTime = '22:00',
    this.identityScore = 0,
    this.level = 1,
    this.totalXp = 0,
    this.onboardingDone = false,
    this.focusCustomDuration = 25,
    this.soundMode = 'SILENCE',
  });
}
