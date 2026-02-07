import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/plan.dart';

class PlanStorage {
  static const String _boxName = 'plans';
  static bool _initialized = false;

  // Call this from main() to initialize
  static Future<void> initialize() async {
    await _ensureInitialized();
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<Plan>(_boxName);
    }
  }

  static Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await Hive.initFlutter();
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(PlanAdapter());
      }
      _initialized = true;
    }
  }

  static Future<Box<Plan>?> get _box async {
    await _ensureInitialized();
    
    if (!Hive.isBoxOpen(_boxName)) {
      try {
        await Hive.openBox<Plan>(_boxName);
      } catch (e) {
        print('Error opening box: $e');
        return null;
      }
    }
    return Hive.box<Plan>(_boxName);
  }

  static Box<Plan>? get _boxSync {
    if (!Hive.isBoxOpen(_boxName)) {
      return null;
    }
    return Hive.box<Plan>(_boxName);
  }

  // Generate a unique key based on the actual date
  static String _getDateKey(DateTime date) {
    return 'date_${date.year}_${date.month}_${date.day}';
  }

  // Save plans for a specific date
  static Future<void> savePlansForDate(
    DateTime date,
    List<Plan> plans,
  ) async {
    final box = await _box;
    if (box == null) return;
    
    final key = _getDateKey(date);
    // Clear existing plans for this day
    await clearPlansForDate(date);
    
    // Save new plans
    for (var i = 0; i < plans.length; i++) {
      await box.put('${key}_$i', plans[i]);
    }
  }

  // Load plans for a specific date
  static List<Plan> loadPlansForDate(DateTime date) {
    final box = _boxSync;
    if (box == null) return [];
    
    final key = _getDateKey(date);
    final List<Plan> plans = [];
    
    // Load all plans that start with this day's key
    for (var entry in box.toMap().entries) {
      if (entry.key.toString().startsWith(key)) {
        plans.add(entry.value);
      }
    }
    
    return plans;
  }

  // Clear all plans for a specific date
  static Future<void> clearPlansForDate(DateTime date) async {
    final box = await _box;
    if (box == null) return;
    
    final key = _getDateKey(date);
    final keysToDelete = box.keys
        .where((k) => k.toString().startsWith(key))
        .toList();
    
    for (var k in keysToDelete) {
      await box.delete(k);
    }
  }

  // Delete a specific plan
  static Future<void> deletePlan(String planId, DateTime date) async {
    final box = await _box;
    if (box == null) return;
    
    final key = _getDateKey(date);
    final keysToDelete = <dynamic>[];
    
    for (var entry in box.toMap().entries) {
      if (entry.key.toString().startsWith(key) && entry.value.id == planId) {
        keysToDelete.add(entry.key);
      }
    }
    
    for (var k in keysToDelete) {
      await box.delete(k);
    }
  }

  // Debug: Print all saved data
  static void debugPrintAllData() {
    final box = _boxSync;
    if (box == null) {
      print('Box not open');
      return;
    }
    
    print('===== ALL SAVED PLANS =====');
    print('Total entries: ${box.length}');
    
    if (box.isEmpty) {
      print('No data saved yet');
    } else {
      for (var entry in box.toMap().entries) {
        print('Key: ${entry.key}');
        print('  Description: ${entry.value.description}');
        print('  Created: ${entry.value.createdAt}');
        print('---');
      }
    }
    print('===========================');
  }

  // Get all data as a readable map
  static Map<String, List<Plan>> getAllDataGrouped() {
    final box = _boxSync;
    if (box == null) return {};
    
    final Map<String, List<Plan>> grouped = {};
    
    for (var entry in box.toMap().entries) {
      final keyStr = entry.key.toString();
      final baseKey = keyStr.contains('_') ? keyStr.substring(0, keyStr.lastIndexOf('_')) : keyStr;
      
      if (!grouped.containsKey(baseKey)) {
        grouped[baseKey] = [];
      }
      grouped[baseKey]!.add(entry.value);
    }
    
    return grouped;
  }
}
