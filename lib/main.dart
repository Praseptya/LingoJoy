import 'package:flutter/material.dart';
import 'utils/app_theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const LingoJoyApp());
}

class LingoJoyApp extends StatelessWidget {
  const LingoJoyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LingoJoy',
      theme: AppTheme.themeData(),
      home: const SplashScreen(),
    );
  }
}
