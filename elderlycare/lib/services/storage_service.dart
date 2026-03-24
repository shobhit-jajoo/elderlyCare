import 'package:hive_flutter/hive_flutter.dart';
import '../models/medication.dart';
import '../models/settings.dart'; // ✅ NEW

class StorageService {
  static const String boxName = "medications";
  static const String settingsBox = "settings";

  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(MedicationAdapter());
    Hive.registerAdapter(AppSettingsAdapter()); // ✅ NEW

    await Hive.openBox<Medication>(boxName);
    await Hive.openBox<AppSettings>(settingsBox);

    /// ✅ Ensure settings exists
    if (Hive.box<AppSettings>(settingsBox).isEmpty) {
      Hive.box<AppSettings>(settingsBox).add(AppSettings());
    }
  }

  /// ---------------- MEDICATION ----------------

  static Box<Medication> getBox() {
    return Hive.box<Medication>(boxName);
  }

  static Future<void> addMedication(Medication med) async {
    final box = getBox();
    await box.add(med);
  }

  static List<Medication> getAllMedications() {
    final box = getBox();
    return box.values.toList();
  }

  static Future<void> deleteMedication(int index) async {
    final box = getBox();
    await box.deleteAt(index);
  }

  /// ---------------- SETTINGS ----------------

  static AppSettings getSettings() {
    return Hive.box<AppSettings>(settingsBox).getAt(0)!;
  }

  static Future<void> saveSettings(AppSettings settings) async {
    await settings.save();
  }
}