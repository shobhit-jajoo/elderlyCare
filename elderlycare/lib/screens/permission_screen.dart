import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';
class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {

  @override
  void initState() {
    super.initState();
    checkPermissions();
  }

  /// ✅ Check if already granted
  Future<void> checkPermissions() async {
  final prefs = await SharedPreferences.getInstance();

  final alreadyDone = prefs.getBool("permissions_done") ?? false;

  final notif = await Permission.notification.isGranted;

  if (notif && alreadyDone) {
    navigateToHome();
  }
}

  /// 🔔 Request permissions
 Future<void> requestPermissions() async {
  final notifStatus = await Permission.notification.request();

  if (notifStatus.isGranted) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("permissions_done", true); // ✅ SAVE

    await openExactAlarmSettings();
  }
}

  /// ⏰ Open exact alarm screen (best possible)
  Future<void> openExactAlarmSettings() async {
    final intent = AndroidIntent(
      action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
    );

    await intent.launch();
  }

  void navigateToHome() {
    Navigator.pushReplacementNamed(context, "/home");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Icon(Icons.notifications_active, size: 80),

            const SizedBox(height: 20),

            const Text(
              "Enable Permissions",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            const Text(
              "We need notification & alarm permissions to remind you on time.",
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: requestPermissions,
              child: const Text("Enable Permissions"),
            ),

            const SizedBox(height: 10),

            TextButton(
              onPressed: navigateToHome,
              child: const Text("Continue"),
            ),
          ],
        ),
      ),
    );
  }
}