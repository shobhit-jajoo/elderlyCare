import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../services/storage_service.dart';
import '../models/settings.dart';

class ManageScreen extends StatefulWidget {
  const ManageScreen({super.key});

  @override
  State<ManageScreen> createState() => _ManageScreenState();
}

class _ManageScreenState extends State<ManageScreen> {
  List<Medication> meds = [];
  late AppSettings settings;

  @override
  void initState() {
    super.initState();
    meds = StorageService.getAllMedications();
    settings = StorageService.getSettings();
  }

  @override
  Widget build(BuildContext context) {
    final medicines = meds.where((m) => m.type == "medicine").toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Manage Reminders")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          /// 💊 Medicines
          const Text("Medicines", style: TextStyle(fontSize: 18)),
          ...medicines.map((med) {
            return Card(
              child: ListTile(
                title: Text(med.name),
                subtitle: Text(med.time),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    final index = meds.indexOf(med);
                    await StorageService.deleteMedication(index);
                    setState(() {
                      meds.remove(med);
                    });
                  },
                ),
                onTap: () {
                  // TODO: edit medicine
                },
              ),
            );
          }),

          const SizedBox(height: 20),

          /// 💧 Water Settings
          const Text("Water Reminder"),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text("Frequency"),
                  trailing: DropdownButton<int>(
                    value: settings.waterFrequency,
                    items: [30, 60, 120]
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text("$e min"),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        settings.waterFrequency = val!;
                        settings.save();
                      });
                    },
                  ),
                ),
                SwitchListTile(
                  title: const Text("Sound + TTS"),
                  value: settings.waterSound,
                  onChanged: (val) {
                    setState(() {
                      settings.waterSound = val;
                      settings.save();
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// 🏃 Exercise
          const Text("Exercise"),
          SwitchListTile(
            title: const Text("Enable Exercise"),
            value: settings.exerciseEnabled,
            onChanged: (val) {
              setState(() {
                settings.exerciseEnabled = val;
                settings.save();
              });
            },
          ),

          SwitchListTile(
            title: const Text("Sound + TTS"),
            value: settings.exerciseSound,
            onChanged: (val) {
              setState(() {
                settings.exerciseSound = val;
                settings.save();
              });
            },
          ),
        ],
      ),
    );
  }
}