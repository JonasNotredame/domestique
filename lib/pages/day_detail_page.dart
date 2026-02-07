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
      // Sort plans by time (converted to minutes for proper 24h comparison)
      _plans.sort((a, b) {
        if (a.fromTime == null || b.fromTime == null) return 0;
        return _timeToMinutes(a.fromTime!) - _timeToMinutes(b.fromTime!);
      });
    });
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return 0;
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    return hours * 60 + minutes;
  }

  Future<void> _savePlans() async {
    await PlanStorage.savePlansForDate(widget.date, _plans);
  }

  void _addPlan() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('What do you want to add?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCategoryOption(
                context,
                'Meal',
                Icons.restaurant,
                Colors.orange,
                () => _showMealDialog(),
              ),
              const SizedBox(height: 8),
              _buildCategoryOption(
                context,
                'Training',
                Icons.fitness_center,
                Colors.red,
                () => _showTrainingDialog(),
              ),
              const SizedBox(height: 8),
              _buildCategoryOption(
                context,
                'Work',
                Icons.work,
                Colors.blue,
                () => _showWorkDialog(),
              ),
              const SizedBox(height: 8),
              _buildCategoryOption(
                context,
                'Sleep/Wake',
                Icons.bedtime,
                Colors.purple,
                () => _showSleepDialog(),
              ),
              const SizedBox(height: 8),
              _buildCategoryOption(
                context,
                'Other',
                Icons.add_circle_outline,
                Colors.grey,
                () => _showCustomDialog(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryOption(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMealDialog() {
    final titleController = TextEditingController();
    final fromTimeController = TextEditingController();
    final toTimeController = TextEditingController();
    final descriptionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Meal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Meal Type',
                    hintText: 'e.g., Breakfast, Lunch, Dinner',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: fromTimeController,
                        decoration: const InputDecoration(
                          labelText: 'From',
                          hintText: '7:20',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.datetime,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: toTimeController,
                        decoration: const InputDecoration(
                          labelText: 'To',
                          hintText: '7:40',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.datetime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'What to eat',
                    hintText: 'Enter meal details...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => _savePlanData(
                titleController.text,
                fromTimeController.text,
                toTimeController.text,
                null,
                descriptionController.text,
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showTrainingDialog() {
    final titleController = TextEditingController(text: 'Training');
    final fromTimeController = TextEditingController();
    final toTimeController = TextEditingController();
    final durationController = TextEditingController();
    final descriptionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Training'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Training Type',
                    hintText: 'e.g., Cycling, Running, Gym',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: fromTimeController,
                        decoration: const InputDecoration(
                          labelText: 'From',
                          hintText: '17:00',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.datetime,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: toTimeController,
                        decoration: const InputDecoration(
                          labelText: 'To',
                          hintText: '18:30',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.datetime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duration',
                    hintText: 'e.g., 1h30, 2h',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Workout Details',
                    hintText: 'e.g., over/unders 4x8, intervals...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => _savePlanData(
                titleController.text,
                fromTimeController.text,
                toTimeController.text,
                durationController.text,
                descriptionController.text,
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showWorkDialog() {
    final titleController = TextEditingController(text: 'Work');
    final fromTimeController = TextEditingController();
    final toTimeController = TextEditingController();
    final durationController = TextEditingController();
    final descriptionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Work'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Activity',
                    hintText: 'e.g., Work, Meeting, Study',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: fromTimeController,
                        decoration: const InputDecoration(
                          labelText: 'From',
                          hintText: '8:00',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.datetime,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: toTimeController,
                        decoration: const InputDecoration(
                          labelText: 'To',
                          hintText: '12:00',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.datetime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duration',
                    hintText: 'e.g., 4h, 8h',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'Enter details...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => _savePlanData(
                titleController.text,
                fromTimeController.text,
                toTimeController.text,
                durationController.text,
                descriptionController.text,
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showSleepDialog() {
    final titleController = TextEditingController();
    final timeController = TextEditingController();
    final descriptionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Sleep/Wake'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Activity',
                    hintText: 'e.g., Wake, Sleep, No screen',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: timeController,
                  decoration: const InputDecoration(
                    labelText: 'Time',
                    hintText: 'e.g., 7:00, 22:30',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.datetime,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'Enter details...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => _savePlanData(
                titleController.text,
                timeController.text,
                null,
                null,
                descriptionController.text,
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showCustomDialog() {
    final titleController = TextEditingController();
    final fromTimeController = TextEditingController();
    final toTimeController = TextEditingController();
    final durationController = TextEditingController();
    final descriptionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Custom Activity'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Activity',
                    hintText: 'e.g., Shopping, Errands',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: fromTimeController,
                        decoration: const InputDecoration(
                          labelText: 'From',
                          hintText: '14:00',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.datetime,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: toTimeController,
                        decoration: const InputDecoration(
                          labelText: 'To (optional)',
                          hintText: '15:00',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.datetime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duration (optional)',
                    hintText: 'e.g., 1h, 30min',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Details (optional)',
                    hintText: 'Enter details...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => _savePlanData(
                titleController.text,
                fromTimeController.text,
                toTimeController.text,
                durationController.text,
                descriptionController.text,
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _savePlanData(String title, String fromTime, String? toTime, String? duration, String description) async {
    if (title.isNotEmpty && fromTime.isNotEmpty) {
      final plan = Plan(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        description: description.trim().isEmpty ? title : description.trim(),
        createdAt: DateTime.now(),
        title: title.trim(),
        fromTime: fromTime.trim(),
        toTime: toTime?.trim().isEmpty ?? true ? null : toTime!.trim(),
        duration: duration?.trim().isEmpty ?? true ? null : duration!.trim(),
      );
      setState(() {
        _plans.add(plan);
        _plans.sort((a, b) {
          if (a.fromTime == null || b.fromTime == null) return 0;
          return _timeToMinutes(a.fromTime!) - _timeToMinutes(b.fromTime!);
        });
      });
      await _savePlans();
      Navigator.pop(context);
    }
  }

  void _editPlan(int index) {
    final plan = _plans[index];
    final titleController = TextEditingController(text: plan.title);
    final fromTimeController = TextEditingController(text: plan.fromTime);
    final toTimeController = TextEditingController(text: plan.toTime ?? '');
    final durationController = TextEditingController(text: plan.duration ?? '');
    final descriptionController = TextEditingController(text: plan.description);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Plan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: fromTimeController,
                        decoration: const InputDecoration(
                          labelText: 'From',
                          hintText: '7:20',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.datetime,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: toTimeController,
                        decoration: const InputDecoration(
                          labelText: 'To (optional)',
                          hintText: '8:00',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.datetime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duration (optional)',
                    hintText: 'e.g., 1h 30min',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _updatePlanData(
                index,
                titleController.text,
                fromTimeController.text,
                toTimeController.text,
                durationController.text,
                descriptionController.text,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updatePlanData(int index, String title, String fromTime, String toTime, String duration, String description) async {
    if (title.isNotEmpty && fromTime.isNotEmpty) {
      final plan = _plans[index];
      final updatedPlan = Plan(
        id: plan.id, // Keep the same ID
        description: description.trim().isEmpty ? title : description.trim(),
        createdAt: plan.createdAt,
        title: title.trim(),
        fromTime: fromTime.trim(),
        toTime: toTime.trim().isEmpty ? null : toTime.trim(),
        duration: duration.trim().isEmpty ? null : duration.trim(),
      );
      setState(() {
        _plans[index] = updatedPlan;
        _plans.sort((a, b) {
          if (a.fromTime == null || b.fromTime == null) return 0;
          return _timeToMinutes(a.fromTime!) - _timeToMinutes(b.fromTime!);
        });
      });
      await _savePlans();
      Navigator.pop(context);
    }
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
                        final plan = _plans[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Time
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        plan.toTime != null
                                            ? '${plan.fromTime ?? "--:--"} - ${plan.toTime}'
                                            : plan.fromTime ?? '--:--',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Title and duration
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  plan.title ?? 'Activity',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              if (plan.duration != null)
                                                Text(
                                                  '(${plan.duration})',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[600],
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          // Description
                                          if (plan.description.isNotEmpty && 
                                              plan.description != plan.title) ...[
                                            const SizedBox(height: 6),
                                            Text(
                                              plan.description,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[700],
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    // Edit button
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      color: Colors.blue[400],
                                      onPressed: () => _editPlan(index),
                                    ),
                                    // Delete button
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 20),
                                      color: Colors.red[400],
                                      onPressed: () => _deletePlan(index),
                                    ),
                                  ],
                                ),
                              ],
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
