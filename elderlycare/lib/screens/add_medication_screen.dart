import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import 'dart:math';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final TextEditingController nameController = TextEditingController();

  TimeOfDay? selectedTime;
  List<int> selectedDays = []; // 1=Mon, 7=Sun
  final List<String> weekDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

  String selectedType = "medicine";

  /// Water config
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  int frequencyMinutes = 60;

  void pickTime(Function(TimeOfDay) onPicked) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4A90E2),
              onPrimary: Colors.white,
              onSurface: Color(0xFF2C3E50),
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) onPicked(time);
  }

  void saveMedication() async {
    // ✅ 1. Validation Checks (Shows an error popup if something is missing)
    if (selectedType == "medicine" && (nameController.text.isEmpty || selectedTime == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a name and pick a time!")));
      return;
    }
    if (selectedType == "water" && (startTime == null || endTime == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a Start and End time for water!")));
      return;
    }

    try {
      int generateSafeId() => Random().nextInt(2147483647); 

      /// 🧠 MEDICINE (manual)
      if (selectedType == "medicine") {
        final med = Medication(
          name: nameController.text,
          time: "${selectedTime!.hour}:${selectedTime!.minute}",
          days: selectedDays,
          type: selectedType,
        );

        await StorageService.addMedication(med);
        final parts = med.time.split(":");
        
        await NotificationService.scheduleMedicine(
          generateSafeId(),
          int.parse(parts[0]),
          int.parse(parts[1]),
          med.name,
        );
      }

      /// 💧 WATER (auto multiple entries)
      else if (selectedType == "water") {
        int start = startTime!.hour * 60 + startTime!.minute;
        int end = endTime!.hour * 60 + endTime!.minute;

        if (start >= end) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Start time must be before End time!")));
          return;
        }

        for (int t = start; t <= end; t += frequencyMinutes) {
          final hour = t ~/ 60;
          final minute = t % 60;

          final med = Medication(
            name: "Drink Water",
            time: "$hour:$minute",
            days: [], 
            type: "water",
          );

          await StorageService.addMedication(med);
          await NotificationService.scheduleMedicine(
            generateSafeId(),
            hour,
            minute,
            "Drink Water",
          );
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
          final parts = t.split(":");

          await NotificationService.scheduleMedicine(
            generateSafeId(), 
            int.parse(parts[0]),
            int.parse(parts[1]),
            "Exercise",
          );
        }
      }

      // ✅ 2. Safely pop the screen to trigger the UI refresh
      if (mounted) Navigator.pop(context);

    } catch (e) {
      // ✅ 3. Catch Android Alarm Limits or Storage crashes
      print("Save Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error saving: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA), // Premium soft background
      appBar: AppBar(
        title: const Text(
          "New Reminder",
          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2C3E50)),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2C3E50)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "What would you like to add?",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF2C3E50)),
                    ),
                    const SizedBox(height: 16),

                    /// 🔥 PREMIUM TYPE SELECTION
                    Row(
                      children: [
                        Expanded(child: _buildTypeCard("Medicine", "medicine", Icons.vaccines, const Color(0xFF4A90E2))),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTypeCard("Water", "water", Icons.water_drop, const Color(0xFF29B6F6))),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTypeCard("Exercise", "exercise", Icons.fitness_center, const Color(0xFFFFA726))),
                      ],
                    ),

                    const SizedBox(height: 32),

                    /// 🧠 MEDICINE UI
                    if (selectedType == "medicine") ...[
                      _buildSectionTitle("Medicine Name"),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: TextField(
                          controller: nameController,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            hintText: "e.g. Paracetamol",
                            hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w400),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildSectionTitle("Reminder Time"),
                      const SizedBox(height: 8),
                      _buildTimePickerButton(
                        label: selectedTime == null ? "Select Time" : selectedTime!.format(context),
                        icon: Icons.access_time_filled_rounded,
                        onTap: () => pickTime((t) => setState(() => selectedTime = t)),
                      ),
                      const SizedBox(height: 24),

                      _buildSectionTitle("Schedule"),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          children: [
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text("Everyday", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                              activeColor: const Color(0xFF4A90E2),
                              value: selectedDays.length == 7,
                              onChanged: (isEveryday) {
                                setState(() {
                                  if (isEveryday) {
                                    selectedDays = [1, 2, 3, 4, 5, 6, 7];
                                  } else {
                                    selectedDays.clear();
                                  }
                                });
                              },
                            ),
                            const Divider(),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: List.generate(7, (index) {
                                final dayValue = index + 1;
                                final isSelected = selectedDays.contains(dayValue);
                                return ChoiceChip(
                                  label: Text(
                                    weekDays[index],
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      color: isSelected ? Colors.white : Colors.grey.shade600,
                                    ),
                                  ),
                                  selectedColor: const Color(0xFF4A90E2),
                                  backgroundColor: const Color(0xFFF4F7FA),
                                  selected: isSelected,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  showCheckmark: false,
                                  onSelected: (_) {
                                    setState(() {
                                      isSelected ? selectedDays.remove(dayValue) : selectedDays.add(dayValue);
                                    });
                                  },
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ],

                    /// 💧 WATER UI
                    if (selectedType == "water") ...[
                      _buildSectionTitle("Hydration Window"),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTimePickerButton(
                              label: startTime == null ? "Start" : startTime!.format(context),
                              icon: Icons.wb_sunny_rounded,
                              onTap: () => pickTime((t) => setState(() => startTime = t)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTimePickerButton(
                              label: endTime == null ? "End" : endTime!.format(context),
                              icon: Icons.nights_stay_rounded,
                              onTap: () => pickTime((t) => setState(() => endTime = t)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      _buildSectionTitle("Remind me every"),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: frequencyMinutes,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF4A90E2)),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50)),
                            items: [30, 60, 90, 120].map((e) {
                              return DropdownMenuItem(
                                value: e,
                                child: Text("$e minutes"),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => frequencyMinutes = val!),
                          ),
                        ),
                      ),
                    ],

                    /// 🏃 EXERCISE UI
                    if (selectedType == "exercise") ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFA726).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFFA726).withOpacity(0.3), width: 2),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.directions_run_rounded, size: 50, color: Color(0xFFF57C00)),
                            SizedBox(height: 16),
                            Text(
                              "Standard Exercise Routine",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Reminders will be automatically set for 8:00 AM and 5:00 PM everyday.",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: Color(0xFFEF6C00)),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            /// 🔥 BOTTOM SAVE BUTTON
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5)),
                ],
              ),
              child: GestureDetector(
                onTap: saveMedication,
                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF4A90E2).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      "Save Reminder",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard(String label, String type, IconData icon, Color color) {
    bool isSelected = selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedType = type;
          if (type == "medicine") nameController.clear();
          if (type != "medicine") nameController.text = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (isSelected) BoxShadow(color: color.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))
            else BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: isSelected ? Colors.white : color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isSelected ? Colors.white : const Color(0xFF2C3E50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePickerButton({required String label, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF4A90E2).withOpacity(0.2), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
            Icon(icon, color: const Color(0xFF4A90E2)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.grey.shade600, letterSpacing: 0.5),
    );
  }
}