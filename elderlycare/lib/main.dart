import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart'; // ✅ Added Splash Screen Package

import 'screens/home_screen.dart';
import 'screens/permission_screen.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'services/notification_service.dart';

void main() async {
  // ✅ 1. Bind the widgets and HOLD the splash screen on the screen
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // ✅ 2. Do all your heavy background loading while the logo is showing
  await StorageService.init();
  await NotificationService.init();

  // ✅ 3. Check Notification Permission
  final notifGranted = await Permission.notification.isGranted;
  
  // ✅ 4. Check Exact Alarm Permission (Android Only)
  bool exactAlarmGranted = true;
  if (Platform.isAndroid) {
    exactAlarmGranted = await Permission.scheduleExactAlarm.isGranted;
  }

  // ✅ 5. ONLY start at home if BOTH are granted
  bool startAtHome = notifGranted && exactAlarmGranted;

  // ✅ 6. Initialization is done! Remove the splash screen smoothly
  FlutterNativeSplash.remove();

  // ✅ 7. Run the app
  runApp(ElderlyCareApp(startAtHome: startAtHome));
}

class ElderlyCareApp extends StatelessWidget {
  final bool startAtHome;

  const ElderlyCareApp({super.key, required this.startAtHome});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ElderlyCare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // 🔥 Strict Gatekeeper routes the user to the correct screen instantly
      home: startAtHome ? const HomeScreen() : const PermissionScreen(),
      routes: {
        "/home": (context) => const HomeScreen(),
      },
    );
  }
}