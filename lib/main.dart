import 'package:flutter/material.dart';
import 'screens.dart';
import 'store.dart';

final store = AppStore();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await store.load();
  runApp(const VisaTrackerApp());
}

class VisaTrackerApp extends StatelessWidget {
  const VisaTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF7C4DFF),
      brightness: Brightness.dark,
      primary: const Color(0xFF8E6BFF),
      secondary: const Color(0xFF3D8BFF),
    );
    return MaterialApp(
      title: 'Visa Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFF0B1020),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B1020),
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF151B30),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF151B30),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
