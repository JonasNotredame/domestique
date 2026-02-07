import 'package:flutter/material.dart';
import 'pages/main_screen.dart';
import 'services/plan_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await PlanStorage.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Domestique',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}
