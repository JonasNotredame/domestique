enum TodoImportance {
  high,
  medium,
  low,
}

class TodoItem {
  final String id;
  final String title;
  final TodoImportance importance;
  final DateTime createdAt;
  final bool isDone;

  TodoItem({
    required this.id,
    required this.title,
    required this.importance,
    required this.createdAt,
    this.isDone = false,
  });

  TodoItem copyWith({
    String? id,
    String? title,
    TodoImportance? importance,
    DateTime? createdAt,
    bool? isDone,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      importance: importance ?? this.importance,
      createdAt: createdAt ?? this.createdAt,
      isDone: isDone ?? this.isDone,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'importance': importance.name,
      'createdAt': createdAt.toIso8601String(),
      'isDone': isDone,
    };
  }

  factory TodoItem.fromMap(Map<String, dynamic> map) {
    return TodoItem(
      id: map['id'] as String,
      title: map['title'] as String,
      importance: TodoImportance.values.firstWhere(
        (item) => item.name == map['importance'],
        orElse: () => TodoImportance.low,
      ),
      createdAt: DateTime.parse(map['createdAt'] as String),
      isDone: map['isDone'] as bool? ?? false,
    );
  }
}
