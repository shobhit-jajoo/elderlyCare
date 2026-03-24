import 'package:hive/hive.dart';

part 'settings.g.dart';

@HiveType(typeId: 1)
class AppSettings extends HiveObject {
  @HiveField(0)
  int waterFrequency; // minutes

  @HiveField(1)
  String waterStart;

  @HiveField(2)
  String waterEnd;

  @HiveField(3)
  bool waterSound;

  @HiveField(4)
  bool exerciseEnabled;

  @HiveField(5)
  bool exerciseSound;

  AppSettings({
    this.waterFrequency = 60,
    this.waterStart = "8:0",
    this.waterEnd = "20:0",
    this.waterSound = true,
    this.exerciseEnabled = true,
    this.exerciseSound = true,
  });
}