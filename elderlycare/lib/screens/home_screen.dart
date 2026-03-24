import 'package:flutter/material.dart';
import 'add_medication_screen.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../models/medication.dart';
import 'manage_screen.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String greeting = "";
  List<Medication> meds = [];

  @override
  void initState() {
    super.initState();
    greeting = getGreeting();
    loadMeds();
  }

  void loadMeds() {
    meds = StorageService.getAllMedications();
    setState(() {});
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning ☀️";
    if (hour < 18) return "Good Afternoon 🌤️";
    return "Good Evening 🌙";
  }

  /// 🔥 Get only medicines
  List<Medication> getMedicines() {
    return meds.where((m) => m.type == "medicine").toList();
  }

  /// 💧 Check water exists
  bool hasWater() {
    return meds.any((m) => m.type == "water");
  }

  /// 🏃 Check exercise exists
  bool hasExercise() {
    return meds.any((m) => m.type == "exercise");
  }

  /// ✅ Next medicine logic
  Medication? getNextMedication() {
    final medicines = getMedicines();
    if (medicines.isEmpty) return null;

    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;

    Medication? nextMed;
    int minDiff = 24 * 60;

    for (var med in medicines) {
      final parts = med.time.split(":");
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final medMinutes = hour * 60 + minute;

      int diff = medMinutes - nowMinutes;
      if (diff < 0) diff += 24 * 60;

      if (diff < minDiff) {
        minDiff = diff;
        nextMed = med;
      }
    }

    return nextMed;
  }

  @override
  Widget build(BuildContext context) {
    final nextMed = getNextMedication();

    return Scaffold(
      appBar: AppBar(
        title: const Text("ElderlyCare"),
        centerTitle: true,
        elevation: 0,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [

            /// Greeting
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                greeting,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// 🔥 Next Medicine Card
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  nextMed == null
                      ? const Text(
                          "No Medicine",
                          style: TextStyle(color: Colors.white),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Next Medicine",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              nextMed.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              nextMed.time,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                  const Icon(Icons.medication, color: Colors.white, size: 40),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// 🔥 MAIN CONTENT
            Expanded(
              child: Column(
                children: [

                  /// 💧 WATER (only once)
                  if (hasWater())
                    Card(
                      color: Colors.blue.shade50,
                      child: const ListTile(
                        leading: Icon(Icons.water_drop),
                        title: Text("Water Reminder"),
                        subtitle: Text("Active"),
                      ),
                    ),

                  /// 🏃 EXERCISE (only once)
                  if (hasExercise())
                    Card(
                      color: Colors.orange.shade50,
                      child: const ListTile(
                        leading: Icon(Icons.fitness_center),
                        title: Text("Exercise Reminder"),
                        subtitle: Text("Morning & Evening"),
                      ),
                    ),

                  const SizedBox(height: 10),

                  /// 💊 MEDICINES LIST
                  Expanded(
                    child: getMedicines().isEmpty
                        ? const Center(child: Text("No medications added"))
                        : ListView.builder(
                            itemCount: getMedicines().length,
                            itemBuilder: (context, index) {
                              final med = getMedicines()[index];

                              return Card(
                                child: ListTile(
                                  title: Text(med.name),
                                  subtitle: Text("Time: ${med.time}"),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () async {
                                      /// ✅ Correct delete
                                      final originalIndex =
                                          meds.indexOf(med);
                                      await StorageService
                                          .deleteMedication(originalIndex);
                                      loadMeds();
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            /// Quick Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                buildActionButton(Icons.add, "Add"),
                buildActionButton(Icons.list, "View"),
                buildActionButton(Icons.phone, "Contacts"),
              ],
            ),

            const SizedBox(height: 20),

            /// SOS Button
            GestureDetector(
              onTap: () {},
              child: Container(
                height: 100,
                width: 100,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    "SOS",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
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

  Widget buildActionButton(IconData icon, String label) {
    return Column(
      children: [
        GestureDetector(
          onTap: () async {
            if (label == "Add") {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddMedicationScreen(),
                ),
              );
              loadMeds();
            }
            if (label == "View") {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const ManageScreen(),
    ),
  );
}
          },
          child: Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, size: 30),
          ),
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    );
  }
}
