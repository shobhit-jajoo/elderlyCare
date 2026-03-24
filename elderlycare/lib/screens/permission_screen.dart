import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {

  /// 🔔 Strict Permission Flow
  Future<void> requestPermissions() async {
    // 1. Ask for standard Notifications
    final notifStatus = await Permission.notification.request();

    // 2. Ask for Exact Alarms (Android 12+)
    // This will open settings, pause, and wait for the user to come back!
    PermissionStatus alarmStatus = PermissionStatus.granted;
    if (Platform.isAndroid) {
      alarmStatus = await Permission.scheduleExactAlarm.request();
    }

    // 3. Strict Check: Are BOTH granted?
    if (notifStatus.isGranted && alarmStatus.isGranted) {
      if (mounted) navigateToHome();
    } else {
      // ❌ Failed: Show a warning message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("BOTH permissions are required for reminders to work!"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void navigateToHome() {
    Navigator.pushReplacementNamed(context, "/home");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA), 
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)
                ],
              ),
              child: const Icon(Icons.notifications_active_rounded, size: 80, color: Color(0xFF4A90E2)),
            ),

            const SizedBox(height: 30),

            const Text(
              "Enable Permissions",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF2C3E50)),
            ),

            const SizedBox(height: 16),

            Text(
              "We need notification and alarm permissions to ensure you never miss a medicine or health routine.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: requestPermissions,
                child: const Text("Allow Permissions", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}