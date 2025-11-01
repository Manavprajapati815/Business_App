import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'providers/worker_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/salary_provider.dart';
import 'providers/work_entry_provider.dart';
import 'providers/advance_provider.dart';
/// Main entry point for the Worker Salary Manager Flutter application.
/// This file sets up the app with state management providers and theme configuration.
/// The main function that starts the Flutter application.
void main() {
  runApp(const MyApp());
}

/**
 * Root widget of the application.
 * Sets up the provider architecture for state management and configures the app's theme.
 */
/// Root widget of the application.
/// Sets up the provider architecture for state management and configures the app's theme.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WorkerProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => SalaryProvider()),
        ChangeNotifierProvider(create: (_) => WorkEntryProvider()),
        ChangeNotifierProvider(create: (_) => AdvanceProvider()),
      ],
      child: MaterialApp(
        title: 'Worker Salary Manager',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
