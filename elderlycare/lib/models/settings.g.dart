// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 1;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      waterFrequency: fields[0] as int,
      waterStart: fields[1] as String,
      waterEnd: fields[2] as String,
      waterSound: fields[3] as bool,
      exerciseEnabled: fields[4] as bool,
      exerciseSound: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.waterFrequency)
      ..writeByte(1)
      ..write(obj.waterStart)
      ..writeByte(2)
      ..write(obj.waterEnd)
      ..writeByte(3)
      ..write(obj.waterSound)
      ..writeByte(4)
      ..write(obj.exerciseEnabled)
      ..writeByte(5)
      ..write(obj.exerciseSound);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
