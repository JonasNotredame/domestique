import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/goal.dart';
import '../services/goal_storage.dart';

class GoalDetailPage extends StatefulWidget {
  final String dayName;
  final int dayNumber;
  final DateTime date;

  const GoalDetailPage({
    super.key,
    required this.dayName,
    required this.dayNumber,
    required this.date,
  });

  @override
  State<GoalDetailPage> createState() => _GoalDetailPageState();
}

class _GoalDetailPageState extends State<GoalDetailPage> {
  final TextEditingController _controller = TextEditingController();
  List<Goal> _goals = [];

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  void _loadGoals() {
    setState(() {
      _goals = GoalStorage.loadGoalsForDate(widget.date);
    });
  }

  Future<void> _saveGoals() async {
    await GoalStorage.saveGoalsForDate(widget.date, _goals);
  }

  void _addGoal() {
    if (_controller.text.trim().isEmpty) return;
    
    final newGoal = Goal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      description: _controller.text.trim(),
      createdAt: DateTime.now(),
    );
    
    setState(() {
      _goals.add(newGoal);
    });
    
    _saveGoals();
    _controller.clear();
  }

  Future<void> _deleteGoal(String id) async {
    await GoalStorage.deleteGoal(id, widget.date);
    _loadGoals();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy').format(widget.date);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.dayName} - $dateStr'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Add a goal',
                      hintText: 'Enter your goal',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addGoal(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addGoal,
                  icon: const Icon(Icons.add_circle),
                  color: Theme.of(context).colorScheme.primary,
                  iconSize: 32,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _goals.isEmpty
                  ? const Center(
                      child: Text(
                        'No goals yet. Add one above!',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _goals.length,
                      itemBuilder: (context, index) {
                        final goal = _goals[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.secondary,
                              child: Icon(
                                Icons.flag,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            title: Text(goal.description),
                            subtitle: Text(
                              'Created: ${DateFormat('HH:mm').format(goal.createdAt)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteGoal(goal.id),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
