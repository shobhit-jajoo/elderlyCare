import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final TextEditingController nameController = TextEditingController();

  TimeOfDay? selectedTime;
  List<int> selectedDays = [];

  String selectedType = "medicine";

  /// Water config
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  int frequencyMinutes = 60;

  void pickTime(Function(TimeOfDay) onPicked) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) onPicked(time);
  }

  void saveMedication() async {
    /// 🧠 MEDICINE (manual)
    if (selectedType == "medicine") {
      if (nameController.text.isEmpty || selectedTime == null) return;

      final med = Medication(
        name: nameController.text,
        time: "${selectedTime!.hour}:${selectedTime!.minute}",
        days: selectedDays,
        type: selectedType,
      );

      await StorageService.addMedication(med);
      final parts = med.time.split(":");
      print("Calling schedule...");
await NotificationService.scheduleMedicine(
  DateTime.now().millisecondsSinceEpoch ~/ 1000,
  int.parse(parts[0]),
  int.parse(parts[1]),
  med.name,
);
    }

    /// 💧 WATER (auto multiple entries)
    else if (selectedType == "water") {
      if (startTime == null || endTime == null) return;

      int start = startTime!.hour * 60 + startTime!.minute;
      int end = endTime!.hour * 60 + endTime!.minute;

      for (int t = start; t <= end; t += frequencyMinutes) {
        final hour = t ~/ 60;
        final minute = t % 60;

        final med = Medication(
          name: "Drink Water",
          time: "$hour:$minute",
          days: [], // daily
          type: "water",
        );

        await StorageService.addMedication(med);
      }
    }

    /// 🏃 EXERCISE (fixed times)
    else if (selectedType == "exercise") {
      final times = ["8:0", "17:0"]; // 8 AM & 5 PM

      for (var t in times) {
        final med = Medication(
          name: "Exercise",
          time: t,
          days: [],
          type: "exercise",
        );

        await StorageService.addMedication(med);
      }
    }

    Navigator.pop(context);
  }

  Widget buildTypeButton(String label, String type) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          selectedType = type;
          nameController.text = label;
        });
      },
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Reminder")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [

              /// TYPE SELECTION
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  buildTypeButton("Medicine", "medicine"),
                  buildTypeButton("Water", "water"),
                  buildTypeButton("Exercise", "exercise"),
                ],
              ),

              const SizedBox(height: 20),

              /// 🧠 MEDICINE UI
              if (selectedType == "medicine") ...[
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Medicine Name",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () => pickTime((t) {
                    setState(() => selectedTime = t);
                  }),
                  child: Text(
                    selectedTime == null
                        ? "Select Time"
                        : selectedTime!.format(context),
                  ),
                ),

                const SizedBox(height: 20),

                Wrap(
                  spacing: 8,
                  children: List.generate(7, (index) {
                    return ChoiceChip(
                      label: Text("D${index + 1}"),
                      selected: selectedDays.contains(index + 1),
                      onSelected: (_) {
                        setState(() {
                          selectedDays.contains(index + 1)
                              ? selectedDays.remove(index + 1)
                              : selectedDays.add(index + 1);
                        });
                      },
                    );
                  }),
                ),
              ],

              /// 💧 WATER UI
              if (selectedType == "water") ...[
                ElevatedButton(
                  onPressed: () => pickTime((t) {
                    setState(() => startTime = t);
                  }),
                  child: Text(
                    startTime == null
                        ? "Start Time"
                        : "Start: ${startTime!.format(context)}",
                  ),
                ),

                const SizedBox(height: 10),

                ElevatedButton(
                  onPressed: () => pickTime((t) {
                    setState(() => endTime = t);
                  }),
                  child: Text(
                    endTime == null
                        ? "End Time"
                        : "End: ${endTime!.format(context)}",
                  ),
                ),

                const SizedBox(height: 20),

                DropdownButton<int>(
                  value: frequencyMinutes,
                  items: [30, 60, 120]
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text("Every $e minutes"),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setState(() => frequencyMinutes = val!);
                  },
                ),
              ],

              /// 🏃 EXERCISE UI
              if (selectedType == "exercise") ...[
                const Text(
                  "Exercise reminders will be set at:\n8:00 AM & 5:00 PM",
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: saveMedication,
                child: const Text("Save"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}