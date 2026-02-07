import 'package:flutter/material.dart';
import '../models/plan.dart';
import '../services/plan_storage.dart';
import 'package:intl/intl.dart';

class DayDetailPage extends StatefulWidget {
  final String dayName;
  final int? dayNumber;
  final DateTime date;

  const DayDetailPage({
    super.key,
    required this.dayName,
    this.dayNumber,
    required this.date,
  });

  @override
  State<DayDetailPage> createState() => _DayDetailPageState();
}

class _DayDetailPageState extends State<DayDetailPage> {
  List<Plan> _plans = [];

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  void _loadPlans() {
    setState(() {
      _plans = PlanStorage.loadPlansForDate(widget.date);
    });
  }

  Future<void> _savePlans() async {
    await PlanStorage.savePlansForDate(widget.date, _plans);
  }

  void _addPlan() {
    showDialog(
      context: context,
      builder: (context) {
        String newPlan = '';
        return AlertDialog(
          title: const Text('Add Plan'),
          content: TextField(
            onChanged: (value) => newPlan = value,
            decoration: const InputDecoration(
              hintText: 'Enter your plan',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (newPlan.isNotEmpty) {
                  final plan = Plan(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    description: newPlan,
                    createdAt: DateTime.now(),
                  );
                  setState(() {
                    _plans.add(plan);
                  });
                  await _savePlans();
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePlan(int index) async {
    final plan = _plans[index];
    await PlanStorage.deletePlan(plan.id, widget.date);
    setState(() {
      _plans.removeAt(index);
    });
    await _savePlans();
  }

  @override
  Widget build(BuildContext context) {
    String title = widget.dayNumber != null
        ? '${widget.dayName} ${widget.dayNumber}'
        : widget.dayName;
    
    final dateStr = DateFormat('dd/MM/yyyy').format(widget.date);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            Text(
              dateStr,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Plans for this day:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _plans.isEmpty
                  ? const Center(
                      child: Text(
                        'No plans yet. Add your first plan!',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _plans.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(_plans[index].description),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deletePlan(index),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPlan,
        child: const Icon(Icons.add),
      ),
    );
  }
}
