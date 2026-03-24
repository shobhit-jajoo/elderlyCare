import 'package:hive/hive.dart';

part 'contact.g.dart';

@HiveType(typeId: 2)
class Contact extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String phone;

  Contact({
    required this.name,
    required this.phone,
  });
}