import 'package:hive_flutter/hive_flutter.dart';
import '../models/medication.dart';
import '../models/settings.dart';
import '../models/contact.dart';

class StorageService {
  static const String boxName = "medications";
  static const String settingsBox = "settings";
  static const String contactBox = "contacts";

  static Future<void> init() async {
    await Hive.initFlutter();

    /// 🔥 REGISTER ALL ADAPTERS
    Hive.registerAdapter(MedicationAdapter());
    Hive.registerAdapter(AppSettingsAdapter());
    Hive.registerAdapter(ContactAdapter());

    /// 🔥 OPEN ALL BOXES
    await Hive.openBox<Medication>(boxName);
    await Hive.openBox<AppSettings>(settingsBox);
    await Hive.openBox<Contact>(contactBox);

    /// DEFAULT SETTINGS
    if (Hive.box<AppSettings>(settingsBox).isEmpty) {
      Hive.box<AppSettings>(settingsBox).add(AppSettings());
    }
  }

  /// ---------------- MEDICATION ----------------

  static Box<Medication> getBox() {
    return Hive.box<Medication>(boxName);
  }

  static Future<void> addMedication(Medication med) async {
    await getBox().add(med);
  }

  static List<Medication> getAllMedications() {
    return getBox().values.toList();
  }

  static Future<void> deleteMedication(int index) async {
    await getBox().deleteAt(index);
  }

  /// ---------------- CONTACTS ----------------

  static Box<Contact> getContactBox() {
    return Hive.box<Contact>(contactBox);
  }

  static List<Contact> getAllContacts() {
    return getContactBox().values.toList();
  }

  static Future<void> addContact(Contact c) async {
    await getContactBox().add(c);
  }

  static Future<void> deleteContact(int index) async {
    await getContactBox().deleteAt(index);
  }

  static Future<void> updateContact(int index, Contact c) async {
    await getContactBox().putAt(index, c);
  }

  /// ---------------- SETTINGS ----------------

  static AppSettings getSettings() {
    return Hive.box<AppSettings>(settingsBox).getAt(0)!;
  }

  static Future<void> saveSettings(AppSettings settings) async {
    await settings.save();
  }
}