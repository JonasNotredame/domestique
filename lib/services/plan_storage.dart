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
    await _migrateDateBasedPlansIfNeeded();
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

  // Generate a recurring key based on weekday (1 = Monday, 7 = Sunday)
  static String _getDateKey(DateTime date) {
    return 'weekday_${date.weekday}';
  }

  static DateTime? _parseLegacyDateKey(String key) {
    final regex = RegExp(r'^date_(\d+)_(\d+)_(\d+)_\d+$');
    final match = regex.firstMatch(key);
    if (match == null) return null;

    final year = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final day = int.tryParse(match.group(3)!);
    if (year == null || month == null || day == null) return null;

    return DateTime(year, month, day);
  }

  static Future<void> _migrateDateBasedPlansIfNeeded() async {
    final box = await _box;
    if (box == null) return;

    final hasLegacyKeys = box.keys.any((k) => k.toString().startsWith('date_'));
    if (!hasLegacyKeys) return;

    final Map<int, DateTime> latestDateByWeekday = {};
    final Map<int, List<Plan>> latestPlansByWeekday = {};

    for (var entry in box.toMap().entries) {
      final key = entry.key.toString();
      if (!key.startsWith('date_')) continue;

      final parsedDate = _parseLegacyDateKey(key);
      if (parsedDate == null) continue;

      final weekday = parsedDate.weekday;
      final currentLatest = latestDateByWeekday[weekday];

      if (currentLatest == null || parsedDate.isAfter(currentLatest)) {
        latestDateByWeekday[weekday] = parsedDate;
      }
    }

    for (var weekday in latestDateByWeekday.keys) {
      final date = latestDateByWeekday[weekday]!;
      final legacyPrefix = 'date_${date.year}_${date.month}_${date.day}';

      final entriesForDate = box.toMap().entries.where(
        (entry) => entry.key.toString().startsWith(legacyPrefix),
      ).toList();

      entriesForDate.sort((a, b) {
        final aIndex = int.tryParse(a.key.toString().split('_').last) ?? 0;
        final bIndex = int.tryParse(b.key.toString().split('_').last) ?? 0;
        return aIndex.compareTo(bIndex);
      });

      latestPlansByWeekday[weekday] = entriesForDate.map((e) => e.value).toList();
    }

    for (var weekday in latestPlansByWeekday.keys) {
      final weekdayPrefix = 'weekday_$weekday';
      final existingWeekdayKeys = box.keys
          .where((k) => k.toString().startsWith(weekdayPrefix))
          .toList();

      for (var key in existingWeekdayKeys) {
        await box.delete(key);
      }

      final plans = latestPlansByWeekday[weekday]!;
      for (var i = 0; i < plans.length; i++) {
        await box.put('${weekdayPrefix}_$i', plans[i]);
      }
    }

    final legacyKeys = box.keys.where((k) => k.toString().startsWith('date_')).toList();
    for (var key in legacyKeys) {
      await box.delete(key);
    }
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
    final matchingEntries = box.toMap().entries
        .where((entry) => entry.key.toString().startsWith(key))
        .toList();

    matchingEntries.sort((a, b) {
      final aIndex = int.tryParse(a.key.toString().split('_').last) ?? 0;
      final bIndex = int.tryParse(b.key.toString().split('_').last) ?? 0;
      return aIndex.compareTo(bIndex);
    });

    final List<Plan> plans = matchingEntries.map((entry) => entry.value).toList();
    
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
