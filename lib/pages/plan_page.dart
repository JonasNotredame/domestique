import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'day_detail_page.dart';
import '../models/plan.dart';
import '../services/plan_storage.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  final List<String> _weekDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  DateTime _getDateForWeekDay(int weekdayIndex) {
    final today = DateTime.now();
    final currentWeekday = today.weekday; // 1 = Monday, 7 = Sunday
    final targetWeekday = weekdayIndex + 1; // Convert 0-6 index to 1-7
    final difference = targetWeekday - currentWeekday;
    return today.add(Duration(days: difference));
  }

  Future<void> _navigateToDay(String dayName, int? dayNumber, DateTime date) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DayDetailPage(
          dayName: dayName,
          dayNumber: dayNumber,
          date: date,
        ),
      ),
    );
    // Refresh after returning
    setState(() {});
  }

  Future<void> _exportPlan() async {
    final exportData = <String, dynamic>{
      'type': 'week',
      'plans': <String, List<Map<String, dynamic>>>{},
    };

    for (int i = 0; i < 7; i++) {
      final date = _getDateForWeekDay(i);
      final plans = PlanStorage.loadPlansForDate(date);
      if (plans.isNotEmpty) {
        exportData['plans'][_weekDays[i]] = plans
            .map((p) => {
                  'title': p.title,
                  'fromTime': p.fromTime,
                  'toTime': p.toTime,
                  'duration': p.duration,
                  'description': p.description,
                })
            .toList();
      }
    }

    final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Weekly Plan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Copy this JSON data:'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  jsonString,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonString));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard!')),
              );
              Navigator.pop(context);
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _importPlan() async {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Weekly Plan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Paste your JSON data:'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 10,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Paste JSON here...',
                ),
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
            onPressed: () async {
              try {
                final jsonData = json.decode(controller.text) as Map<String, dynamic>;
                await _processImportData(jsonData);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Weekly plan imported!')),
                );
                setState(() {});
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Import failed: $e')),
                );
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  Future<void> _processImportData(Map<String, dynamic> data) async {
    if (data['type'] != null && data['type'] != 'week') {
      throw Exception('Only weekly exports are supported');
    }

    final plans = data['plans'] as Map<String, dynamic>?;
    if (plans == null) {
      throw Exception('Invalid data: missing "plans" object');
    }

    for (int i = 0; i < 7; i++) {
      final dayName = _weekDays[i];
      if (!plans.containsKey(dayName)) continue;

      final date = _getDateForWeekDay(i);
      final dayPlans = (plans[dayName] as List)
          .map((p) => Plan(
                id: '${DateTime.now().millisecondsSinceEpoch}_$i',
                title: p['title'],
                fromTime: p['fromTime'],
                toTime: p['toTime'],
                duration: p['duration'],
                description: p['description'] ?? '',
                createdAt: DateTime.now(),
              ))
          .toList();

      await PlanStorage.savePlansForDate(date, dayPlans);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header Section - Takes less space than home page
        Container(
          height: MediaQuery.of(context).size.height * 0.15,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Week Plan',
                        style: TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Build your weekly routine',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _importPlan,
                        icon: const Icon(Icons.file_upload, color: Colors.white),
                        tooltip: 'Import Week Plan',
                      ),
                      IconButton(
                        onPressed: _exportPlan,
                        icon: const Icon(Icons.file_download, color: Colors.white),
                        tooltip: 'Export Week Plan',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        // Content Section
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildWeekView(),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekView() {
    final today = DateTime.now();
    final currentDayOfWeek = today.weekday; // Monday = 1, Sunday = 7

    return ListView.builder(
      itemCount: _weekDays.length,
      itemBuilder: (context, index) {
        final isToday = (index + 1) == currentDayOfWeek;
        final date = _getDateForWeekDay(index);
        final dateStr = DateFormat('dd/MM/yyyy').format(date);
        final dayPlans = PlanStorage.loadPlansForDate(date);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: isToday ? Colors.deepPurple.shade50 : null,
          child: InkWell(
            onTap: () => _navigateToDay(_weekDays[index], null, date),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _weekDays[index],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isToday ? Colors.deepPurple.shade900 : null,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 12,
                              color: isToday ? Colors.deepPurple.shade700 : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: isToday ? Colors.deepPurple.shade900 : Colors.grey,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (dayPlans.isEmpty)
                    Text(
                      'No activities planned',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: dayPlans.take(3).map((plan) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  plan.toTime != null
                                      ? '${plan.fromTime ?? "--:--"} - ${plan.toTime}'
                                      : plan.fromTime ?? '--:--',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  plan.title ?? plan.description,
                                  style: const TextStyle(
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (plan.duration != null)
                                Text(
                                  plan.duration!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  if (dayPlans.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        '+${dayPlans.length - 3} more',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
