import 'package:flutter/material.dart';
import '../models/todo.dart';
import '../services/todo_storage.dart';
import '../services/notification_service.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  List<TodoItem> _todos = [];

  @override
  void initState() {
    super.initState();
    _todos = TodoStorage.loadTodos();
  }

  Future<void> _save() async {
    await TodoStorage.saveTodos(_todos);
  }

  Color _colorForImportance(TodoImportance importance) {
    switch (importance) {
      case TodoImportance.high:
        return Colors.red;
      case TodoImportance.medium:
        return Colors.orange;
      case TodoImportance.low:
        return Colors.green;
    }
  }

  String _labelForImportance(TodoImportance importance) {
    switch (importance) {
      case TodoImportance.high:
        return 'High';
      case TodoImportance.medium:
        return 'Medium';
      case TodoImportance.low:
        return 'Low';
    }
  }

  String _reminderText(TodoImportance importance) {
    switch (importance) {
      case TodoImportance.high:
        return 'Daily at 08:00';
      case TodoImportance.medium:
        return 'Every 2 days at 08:00';
      case TodoImportance.low:
        return 'Weekly at 08:00';
    }
  }

  Future<void> _showAddDialog() async {
    final controller = TextEditingController();
    var selected = TodoImportance.medium;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setInnerState) {
            return AlertDialog(
              title: const Text('Add To-Do'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Task',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TodoImportance>(
                    value: selected,
                    items: TodoImportance.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(_labelForImportance(value)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setInnerState(() {
                          selected = value;
                        });
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Importance',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Reminder: ${_reminderText(selected)}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final title = controller.text.trim();
                    if (title.isEmpty) return;

                    final todo = TodoItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: title,
                      importance: selected,
                      createdAt: DateTime.now(),
                    );

                    setState(() {
                      _todos.insert(0, todo);
                    });
                    await _save();
                    await NotificationService.scheduleForTodo(todo);
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _toggleDone(int index, bool value) async {
    final todo = _todos[index].copyWith(isDone: value);
    setState(() {
      _todos[index] = todo;
    });
    await _save();
    if (value) {
      await NotificationService.cancelForTodo(todo.id);
    } else {
      await NotificationService.scheduleForTodo(todo);
    }
  }

  Future<void> _deleteTodo(int index) async {
    final todo = _todos[index];
    setState(() {
      _todos.removeAt(index);
    });
    await _save();
    await NotificationService.cancelForTodo(todo.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do List'),
      ),
      body: _todos.isEmpty
          ? const Center(
              child: Text('No tasks yet. Add your first task.'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _todos.length,
              itemBuilder: (context, index) {
                final todo = _todos[index];
                final color = _colorForImportance(todo.importance);
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Checkbox(
                      value: todo.isDone,
                      onChanged: (value) => _toggleDone(index, value ?? false),
                    ),
                    title: Text(
                      todo.title,
                      style: TextStyle(
                        decoration:
                            todo.isDone ? TextDecoration.lineThrough : TextDecoration.none,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _labelForImportance(todo.importance),
                            style: TextStyle(color: color, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _reminderText(todo.importance),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteTodo(index),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
