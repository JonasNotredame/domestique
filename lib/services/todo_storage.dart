import 'package:hive/hive.dart';
import '../models/todo.dart';

class TodoStorage {
  static const String _boxName = 'todos';
  static const String _todosKey = 'items';

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

  static List<TodoItem> loadTodos() {
    final raw = _boxSync.get(_todosKey);
    if (raw == null) return [];

    return raw
        .map((entry) => TodoItem.fromMap(Map<String, dynamic>.from(entry as Map)))
        .toList();
  }

  static Future<void> saveTodos(List<TodoItem> todos) async {
    final box = await _box;
    final data = todos.map((todo) => todo.toMap()).toList();
    await box.put(_todosKey, data);
  }
}
