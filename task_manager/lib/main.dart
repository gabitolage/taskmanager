import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'services/camera_service.dart';
import 'screens/task_list_screen.dart';

void main() async {
  // Inicializar o sqflite ffi para Windows
  WidgetsFlutterBinding.ensureInitialized();
  await CameraService.instance.initialize();
  _initializeDatabase();
  runApp(const MyApp());
}

void _initializeDatabase() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  print('Database initialized for Windows');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          filled: true,
          fillColor: Color(0xFFF5F5F5),
        ),
      ),
      home: const TaskListScreen(),
    );
  }
}