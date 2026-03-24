import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/permission_screen.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'services/notification_service.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  await NotificationService.init();
  runApp(const ElderlyCareApp());
}

class ElderlyCareApp extends StatelessWidget {
  const ElderlyCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
  title: 'ElderlyCare',
  debugShowCheckedModeBanner: false,
  theme: AppTheme.lightTheme,
  home: const PermissionScreen(),
routes: {
  "/home": (context) => const HomeScreen(),
},
);
  }
}