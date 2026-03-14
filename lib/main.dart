import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'pages/overview_page.dart';
import 'services/plan_storage.dart';
import 'services/goal_storage.dart';
import 'services/finance_storage.dart';
import 'services/todo_storage.dart';
import 'services/notification_service.dart';
import 'models/plan.dart';
import 'models/goal.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  Hive.registerAdapter(PlanAdapter());
  Hive.registerAdapter(GoalAdapter());
  
  await PlanStorage.initialize();
  await GoalStorage.initialize();
  await FinanceStorage.initialize();
  await TodoStorage.initialize();
  await NotificationService.initialize();
  
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
      home: const OverviewPage(),
    );
  }
}
