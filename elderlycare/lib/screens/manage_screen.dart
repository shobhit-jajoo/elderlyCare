import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import 'dart:math';

class ManageScreen extends StatefulWidget {
  const ManageScreen({super.key});

  @override
  State<ManageScreen> createState() => _ManageScreenState();
}

class _ManageScreenState extends State<ManageScreen> {
  List<Medication> meds = [];

  @override
  void initState() {
    super.initState();
    loadMeds();
  }

  void loadMeds() {
    final box = StorageService.getBox();
    meds = box.values.cast<Medication>().toList();
    setState(() {});
  }

  int generateSafeId() => Random().nextInt(2147483647);

  // --- 💧 WATER LOGIC ---
  List<Medication> get waterMeds => meds.where((m) => m.type == "water").toList();

  String getWaterSummary() {
    if (waterMeds.isEmpty) return "No routine set";
    // Sort by time to find start and end accurately
    final sorted = List<Medication>.from(waterMeds)..sort((a, b) {
        final aMinutes = int.parse(a.time.split(":")[0]) * 60 + int.parse(a.time.split(":")[1]);
        final bMinutes = int.parse(b.time.split(":")[0]) * 60 + int.parse(b.time.split(":")[1]);
        return aMinutes.compareTo(bMinutes);
      });

    final start = sorted.first.time;
    final end = sorted.last.time;
    
    int freq = 60; // Default fallback
    if (sorted.length > 1) {
      final firstMins = int.parse(sorted[0].time.split(":")[0]) * 60 + int.parse(sorted[0].time.split(":")[1]);
      final secondMins = int.parse(sorted[1].time.split(":")[0]) * 60 + int.parse(sorted[1].time.split(":")[1]);
      freq = secondMins - firstMins;
    }

    return "Start: $start • End: $end • Every $freq min";
  }

  Future<void> deleteAllOfType(String type) async {
    // Delete in reverse order so index shifting doesn't break the loop
    for (int i = meds.length - 1; i >= 0; i--) {
      if (meds[i].type == type) {
        await StorageService.deleteMedication(i);
      }
    }
    loadMeds();
  }

  // --- 📝 EDIT DIALOGS ---

  void _showEditMedicineDialog(Medication med, int index) {
    final TextEditingController nameCtrl = TextEditingController(text: med.name);
    TimeOfDay selectedTime = TimeOfDay(
      hour: int.parse(med.time.split(":")[0]),
      minute: int.parse(med.time.split(":")[1]),
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text("Edit Medicine", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: "Medicine Name",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                    leading: const Icon(Icons.access_time_rounded, color: Color(0xFF4A90E2)),
                    title: const Text("Reminder Time", style: TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Text(selectedTime.format(context), style: const TextStyle(fontSize: 16)),
                    onTap: () async {
                      final t = await showTimePicker(context: context, initialTime: selectedTime);
                      if (t != null) setStateDialog(() => selectedTime = t);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A90E2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty) return;
                    
                    // Delete old
                    await StorageService.deleteMedication(index);
                    
                    // Add new
                    final newMed = Medication(
                      name: nameCtrl.text,
                      time: "${selectedTime.hour}:${selectedTime.minute}",
                      days: med.days, // keep existing days
                      type: "medicine",
                    );
                    await StorageService.addMedication(newMed);
                    await NotificationService.scheduleMedicine(generateSafeId(), selectedTime.hour, selectedTime.minute, newMed.name);
                    
                    if (mounted) Navigator.pop(context);
                    loadMeds();
                  },
                  child: const Text("Save Changes", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  void _showEditWaterDialog() {
    TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 20, minute: 0);
    int freq = 60;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text("Edit Hydration Routine", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                    title: const Text("Start Time", style: TextStyle(fontSize: 14)),
                    trailing: Text(startTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () async {
                      final t = await showTimePicker(context: context, initialTime: startTime);
                      if (t != null) setStateDialog(() => startTime = t);
                    },
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                    title: const Text("End Time", style: TextStyle(fontSize: 14)),
                    trailing: Text(endTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () async {
                      final t = await showTimePicker(context: context, initialTime: endTime);
                      if (t != null) setStateDialog(() => endTime = t);
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Remind me every:", style: TextStyle(fontWeight: FontWeight.w600)),
                      DropdownButton<int>(
                        value: freq,
                        underline: const SizedBox(),
                        items: [30, 60, 90, 120].map((e) => DropdownMenuItem(value: e, child: Text("$e min"))).toList(),
                        onChanged: (val) => setStateDialog(() => freq = val!),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF29B6F6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () async {
                    // Wipe old routine
                    await deleteAllOfType("water");
                    
                    // Generate new routine
                    int startMins = startTime.hour * 60 + startTime.minute;
                    int endMins = endTime.hour * 60 + endTime.minute;

                    for (int t = startMins; t <= endMins; t += freq) {
                      final hour = t ~/ 60;
                      final minute = t % 60;
                      final newMed = Medication(name: "Drink Water", time: "$hour:$minute", days: [], type: "water");
                      await StorageService.addMedication(newMed);
                      await NotificationService.scheduleMedicine(generateSafeId(), hour, minute, "Drink Water");
                    }

                    if (mounted) Navigator.pop(context);
                    loadMeds();
                  },
                  child: const Text("Save Routine", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  // --- 🎨 UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    final medicines = meds.where((m) => m.type == "medicine").toList();
    final hasExercise = meds.any((m) => m.type == "exercise");

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA), // Premium soft background
      appBar: AppBar(
        title: const Text("Manage Reminders", style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2C3E50))),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2C3E50)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        physics: const BouncingScrollPhysics(),
        children: [
          
          /// 💊 MEDICINES SECTION
          const Text("Your Medicines", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF2C3E50))),
          const SizedBox(height: 12),
          if (medicines.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Text("No medicines added.", style: TextStyle(color: Colors.grey.shade500)),
            ),
          ...medicines.map((med) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF4A90E2).withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.vaccines_rounded, color: Color(0xFF4A90E2)),
                ),
                title: Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2C3E50))),
                subtitle: Text("Scheduled for ${med.time}", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF5252)),
                  onPressed: () async {
                    final originalIndex = meds.indexOf(med);
                    await StorageService.deleteMedication(originalIndex);
                    loadMeds();
                  },
                ),
                onTap: () => _showEditMedicineDialog(med, meds.indexOf(med)),
              ),
            );
          }),

          const SizedBox(height: 24),

          /// 💧 WATER SECTION
          const Text("Hydration Routine", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF2C3E50))),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF29B6F6).withOpacity(0.3), width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF29B6F6).withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.water_drop_rounded, color: Color(0xFF29B6F6), size: 28),
              ),
              title: const Text("Daily Water", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2C3E50))),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(getWaterSummary(), style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500, fontSize: 13)),
              ),
              trailing: waterMeds.isEmpty 
                ? null 
                : IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF5252)),
                    onPressed: () => deleteAllOfType("water"),
                  ),
              onTap: _showEditWaterDialog,
            ),
          ),

          const SizedBox(height: 32),

          /// 🏃 EXERCISE SECTION
          const Text("Exercise Routine", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF2C3E50))),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFA726).withOpacity(0.3), width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFFFA726).withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.fitness_center_rounded, color: Color(0xFFFFA726), size: 28),
              ),
              title: Text(hasExercise ? "Active Routine" : "No Routine Set", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2C3E50))),
              subtitle: Text(hasExercise ? "Reminders at 8:00 AM & 5:00 PM" : "Tap to add in Add Screen", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
              trailing: !hasExercise 
                ? null 
                : IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF5252)),
                    onPressed: () => deleteAllOfType("exercise"),
                  ),
            ),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}