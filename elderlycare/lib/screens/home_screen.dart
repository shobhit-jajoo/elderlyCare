import 'package:flutter/material.dart';
import 'add_medication_screen.dart';
import '../services/storage_service.dart';
// import '../services/notification_service.dart'; // Keep your original imports
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
      backgroundColor: const Color(0xFFF4F7FA), // Ultra-soft premium background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              /// ✨ BRAND NEW CUSTOM HEADER (Replaces standard AppBar)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4A90E2).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.favorite, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      RichText(
                        text: const TextSpan(
                          text: 'Elderly',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF4A90E2),
                            letterSpacing: -0.5,
                          ),
                          children: [
                            TextSpan(
                              text: 'Care',
                              style: TextStyle(
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: const CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: Color(0xFF2C3E50), size: 26),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              /// 🌅 Greeting Section
              Text(
                greeting,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2C3E50),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Here is your health schedule for today.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

              /// 🔥 Next Medicine Highlight Card
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4A90E2), Color(0xFF1E5799)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28), // Softer, more modern radius
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4A90E2).withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.alarm, color: Colors.white, size: 14),
                                SizedBox(width: 6),
                                Text(
                                  "UPCOMING",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            nextMed?.name ?? "No Upcoming Meds",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            nextMed?.time ?? "You are all caught up!",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    
                    Container(
                      height: 70,
                      width: 70,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                      ),
                      child: const Icon(Icons.vaccines_rounded, color: Colors.white, size: 36),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              /// 📋 Main Content Area (Scrollable)
              
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Daily Routine",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 12),

                    /// 💧 WATER
                    if (hasWater())
                      _buildRoutineTile(
                        icon: Icons.water_drop_rounded,
                        title: "Hydration",
                        subtitle: "Active throughout the day",
                        color: const Color(0xFF29B6F6),
                        bgColor: Colors.lightBlue.shade50.withOpacity(0.5),
                      ),

                    /// 🏃 EXERCISE
                    if (hasExercise())
                      _buildRoutineTile(
                        icon: Icons.fitness_center_rounded,
                        title: "Daily Exercise",
                        subtitle: "Morning & Evening routines",
                        color: const Color(0xFFFFA726),
                        bgColor: Colors.orange.shade50.withOpacity(0.5),
                      ),

                    const SizedBox(height: 20),
                    const Text(
                      "Your Medications",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 12),

                    /// 💊 MEDICINES LIST
                    getMedicines().isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 15,
                                        )
                                      ]
                                    ),
                                    child: Icon(Icons.health_and_safety_rounded, size: 50, color: Colors.grey.shade400),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "No medications scheduled.",
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
  physics: const NeverScrollableScrollPhysics(),
  shrinkWrap: true,
                              itemCount: getMedicines().length,
                              itemBuilder: (context, index) {
                                final med = getMedicines()[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    leading: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4A90E2).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(Icons.medication_liquid_rounded, color: Color(0xFF4A90E2), size: 28),
                                    ),
                                    title: Text(
                                      med.name,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Color(0xFF2C3E50)),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Row(
                                        children: [
                                          Icon(Icons.access_time_filled_rounded, size: 14, color: Colors.grey.shade500),
                                          const SizedBox(width: 4),
                                          Text(
                                            med.time,
                                            style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF5252), size: 26),
                                      onPressed: () async {
                                        final originalIndex = meds.indexOf(med);
                                        await StorageService.deleteMedication(originalIndex);
                                        loadMeds();
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                
                  ],
                ),
              

              const SizedBox(height: 10),

              /// 🛠️ Quick Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  buildActionButton(Icons.add_circle_rounded, "Add Med", const Color(0xFF4CAF50)),
                  buildActionButton(Icons.format_list_bulleted_rounded, "Manage", const Color(0xFF4A90E2)),
                  buildActionButton(Icons.support_agent_rounded, "Contacts", const Color(0xFF9C27B0)),
                ],
              ),

              const SizedBox(height: 24),

              /// 🚨 SOS Button (Premium Panic Button Look)
              Center(
                child: GestureDetector(
                  onTap: () {
                    // TODO: SOS Action
                  },
                  child: Container(
                    height: 80,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF4B4B), Color(0xFFC62828)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF4B4B).withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                        // Inner highlight to make it look like a physical 3D button
                        BoxShadow(
                          color: Colors.white.withOpacity(0.2),
                          blurRadius: 2,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.warning_rounded, color: Colors.white, size: 32),
                        SizedBox(width: 12),
                        Text(
                          "EMERGENCY SOS",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
          ),
        ),
      ),
    );
  }

  /// Helper to build Routine Tiles (Water/Exercise)
  Widget _buildRoutineTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [
            BoxShadow(color: color.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))
          ]),
          child: Icon(icon, color: color, size: 26),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: color.withOpacity(0.9))),
        subtitle: Text(subtitle, style: TextStyle(color: color.withOpacity(0.7), fontWeight: FontWeight.w500)),
      ),
    );
  }

  /// Upgraded Quick Action Buttons
  Widget buildActionButton(IconData icon, String label, Color iconColor) {
    return GestureDetector(
      onTap: () async {
        if (label == "Add Med") {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddMedicationScreen(),
            ),
          );
          loadMeds();
        }
        if (label == "Manage") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ManageScreen(),
            ),
          );
        }
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.26, // Dynamic sizing
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 34, color: iconColor),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Color(0xFF2C3E50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}