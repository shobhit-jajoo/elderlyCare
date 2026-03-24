import 'package:hive/hive.dart';

part 'medication.g.dart';

@HiveType(typeId: 0)
class Medication extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String time;

  @HiveField(2)
  List<int> days;

  @HiveField(3)
  bool isTaken;

  @HiveField(4)
  String type; // ✅ NEW (medicine, water, exercise)

  Medication({
  required this.name,
  required this.time,
  required this.days,
  this.type = "medicine", // ✅ default value (fixes crash)
  this.isTaken = false,
});
}