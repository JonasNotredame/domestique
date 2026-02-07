import 'package:hive/hive.dart';
import '../models/goal.dart';

class GoalStorage {
  static const String _boxName = 'goals';

  static Future<void> initialize() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<List>(_boxName);
    }
  }

  static Box<List>? get _box {
    if (!Hive.isBoxOpen(_boxName)) {
      return null;
    }
    return Hive.box<List>(_boxName);
  }

  static Box<List> get _boxSync {
    return Hive.box<List>(_boxName);
  }

  static String _getDateKey(DateTime date) {
    return 'date_${date.year}_${date.month}_${date.day}';
  }

  static Future<void> saveGoalsForDate(DateTime date, List<Goal> goals) async {
    final box = _box ?? await Hive.openBox<List>(_boxName);
    final key = _getDateKey(date);
    final goalsData = goals.map((g) => {
      'id': g.id,
      'description': g.description,
      'createdAt': g.createdAt.toIso8601String(),
    }).toList();
    await box.put(key, goalsData);
  }

  static List<Goal> loadGoalsForDate(DateTime date) {
    final box = _boxSync;
    final key = _getDateKey(date);
    final data = box.get(key);
    
    if (data == null) return [];
    
    return (data as List).map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      return Goal(
        id: map['id'] as String,
        description: map['description'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
    }).toList();
  }

  static Future<void> clearGoalsForDate(DateTime date) async {
    final box = _box ?? await Hive.openBox<List>(_boxName);
    final key = _getDateKey(date);
    await box.delete(key);
  }

  static Future<void> deleteGoal(String id, DateTime date) async {
    final goals = loadGoalsForDate(date);
    goals.removeWhere((goal) => goal.id == id);
    await saveGoalsForDate(date, goals);
  }

  static Map<String, dynamic>? getNextGoal() {
    final box = _boxSync;
    final today = DateTime.now();
    
    // Check the next 365 days for goals
    for (int i = 0; i < 365; i++) {
      final checkDate = today.add(Duration(days: i));
      final goals = loadGoalsForDate(checkDate);
      
      if (goals.isNotEmpty) {
        return {
          'goal': goals.first,
          'date': checkDate,
        };
      }
    }
    
    return null;
  }
}
