import 'package:hive/hive.dart';
import '../models/finance.dart';

class FinanceStorage {
  static const String _boxName = 'finance';
  static const String _institutionsKey = 'institutions';

  static Future<void> initialize() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<List>(_boxName);
    }
  }

  static Box<List> get _boxSync => Hive.box<List>(_boxName);

  static Future<Box<List>> get _box async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<List>(_boxName);
    }
    return Hive.box<List>(_boxName);
  }

  static List<FinancialInstitution> loadInstitutions() {
    final raw = _boxSync.get(_institutionsKey);
    if (raw == null) return [];

    return raw
        .map(
          (entry) => FinancialInstitution.fromMap(
            Map<String, dynamic>.from(entry as Map),
          ),
        )
        .toList();
  }

  static Future<void> saveInstitutions(List<FinancialInstitution> institutions) async {
    final box = await _box;
    await box.put(
      _institutionsKey,
      institutions.map((institution) => institution.toMap()).toList(),
    );
  }
}
