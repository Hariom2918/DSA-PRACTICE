// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserSettingsModelAdapter extends TypeAdapter<UserSettingsModel> {
  @override
  final int typeId = 4;

  @override
  UserSettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserSettingsModel(
      id: fields[0] as String,
      name: fields[1] as String,
      wakeTime: fields[2] as String,
      sleepTime: fields[3] as String,
      identityScore: fields[4] as int,
      level: fields[5] as int,
      totalXp: fields[6] as int,
      onboardingDone: fields[7] as bool,
      focusCustomDuration: fields[8] as int,
      soundMode: fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, UserSettingsModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.wakeTime)
      ..writeByte(3)
      ..write(obj.sleepTime)
      ..writeByte(4)
      ..write(obj.identityScore)
      ..writeByte(5)
      ..write(obj.level)
      ..writeByte(6)
      ..write(obj.totalXp)
      ..writeByte(7)
      ..write(obj.onboardingDone)
      ..writeByte(8)
      ..write(obj.focusCustomDuration)
      ..writeByte(9)
      ..write(obj.soundMode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettingsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
