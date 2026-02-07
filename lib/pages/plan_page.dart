import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'day_detail_page.dart';
import 'week_detail_page.dart';
import '../services/plan_storage.dart';
import '../models/plan.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  String _selectedView = 'Week';
  final List<String> _viewOptions = ['Week', '4 Weeks'];
  final List<String> _weekDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  DateTime _getDateForWeekDay(int weekdayIndex) {
    final today = DateTime.now();
    final currentWeekday = today.weekday; // 1 = Monday, 7 = Sunday
    final targetWeekday = weekdayIndex + 1; // Convert 0-6 index to 1-7
    final difference = targetWeekday - currentWeekday;
    return today.add(Duration(days: difference));
  }

  DateTime _getDateForMonthDay(int day) {
    final today = DateTime.now();
    return DateTime(today.year, today.month, day);
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
    final exportData = <String, dynamic>{};
    
    if (_selectedView == 'Week') {
      // Export current week
      exportData['type'] = 'week';
      exportData['plans'] = <String, List<Map<String, dynamic>>>{};
      
      for (int i = 0; i < 7; i++) {
        final date = _getDateForWeekDay(i);
        final plans = PlanStorage.loadPlansForDate(date);
        if (plans.isNotEmpty) {
          exportData['plans'][_weekDays[i]] = plans.map((p) => {
            'title': p.title,
            'fromTime': p.fromTime,
            'toTime': p.toTime,
            'duration': p.duration,
            'description': p.description,
          }).toList();
        }
      }
    } else {
      // Export 4 weeks
      exportData['type'] = '4weeks';
      exportData['weeks'] = <Map<String, dynamic>>[];
      
      final today = DateTime.now();
      final firstDayOfMonth = DateTime(today.year, today.month, 1);
      final firstMonday = firstDayOfMonth.subtract(Duration(days: (firstDayOfMonth.weekday - 1) % 7));
      
      for (int week = 0; week < 4; week++) {
        final weekPlans = <String, List<Map<String, dynamic>>>{};
        for (int day = 0; day < 7; day++) {
          final date = firstMonday.add(Duration(days: week * 7 + day));
          final plans = PlanStorage.loadPlansForDate(date);
          if (plans.isNotEmpty) {
            weekPlans[_weekDays[day]] = plans.map((p) => {
              'title': p.title,
              'fromTime': p.fromTime,
              'toTime': p.toTime,
              'duration': p.duration,
              'description': p.description,
            }).toList();
          }
        }
        if (weekPlans.isNotEmpty) {
          exportData['weeks'].add({
            'weekNumber': week + 1,
            'plans': weekPlans,
          });
        }
      }
    }
    
    final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Plan'),
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
            child: const Text('Copy to Clipboard'),
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
        title: const Text('Import Plan'),
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
                  const SnackBar(content: Text('Import successful!')),
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
    if (data['type'] == 'week') {
      // Import week plans
      final plans = data['plans'] as Map<String, dynamic>;
      for (int i = 0; i < 7; i++) {
        final dayName = _weekDays[i];
        if (plans.containsKey(dayName)) {
          final date = _getDateForWeekDay(i);
          final dayPlans = (plans[dayName] as List).map((p) {
            return Plan(
              id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
              title: p['title'],
              fromTime: p['fromTime'],
              toTime: p['toTime'],
              duration: p['duration'],
              description: p['description'],
              createdAt: DateTime.now(),
            );
          }).toList();
          await PlanStorage.savePlansForDate(date, dayPlans);
        }
      }
    } else if (data['type'] == '4weeks') {
      // Import 4 weeks plans
      final weeks = data['weeks'] as List;
      final today = DateTime.now();
      final firstDayOfMonth = DateTime(today.year, today.month, 1);
      final firstMonday = firstDayOfMonth.subtract(Duration(days: (firstDayOfMonth.weekday - 1) % 7));
      
      for (final weekData in weeks) {
        final weekNumber = weekData['weekNumber'] as int;
        final plans = weekData['plans'] as Map<String, dynamic>;
        
        for (int i = 0; i < 7; i++) {
          final dayName = _weekDays[i];
          if (plans.containsKey(dayName)) {
            final date = firstMonday.add(Duration(days: (weekNumber - 1) * 7 + i));
            final dayPlans = (plans[dayName] as List).map((p) {
              return Plan(
                id: DateTime.now().millisecondsSinceEpoch.toString() + weekNumber.toString() + i.toString(),
                title: p['title'],
                fromTime: p['fromTime'],
                toTime: p['toTime'],
                duration: p['duration'],
                description: p['description'],
                createdAt: DateTime.now(),
              );
            }).toList();
            await PlanStorage.savePlansForDate(date, dayPlans);
          }
        }
      }
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
                        tooltip: 'Import Plan',
                      ),
                      IconButton(
                        onPressed: _exportPlan,
                        icon: const Icon(Icons.file_download, color: Colors.white),
                        tooltip: 'Export Plan',
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButton<String>(
                  value: _selectedView,
                  isExpanded: true,
                  items: _viewOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedView = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _selectedView == 'Week'
                      ? _buildWeekView()
                      : _buildMonthView(),
                ),
              ],
            ),
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

  Widget _buildMonthView() {
    final today = DateTime.now();
    final currentMonth = today.month;
    final currentYear = today.year;
    
    // Get first day of the month and find the Monday of that week
    final firstDayOfMonth = DateTime(currentYear, currentMonth, 1);
    final firstMonday = firstDayOfMonth.subtract(Duration(days: (firstDayOfMonth.weekday - 1) % 7));

    return ListView.builder(
      itemCount: 4,
      itemBuilder: (context, index) {
        final weekNumber = index + 1;
        final weekStartDate = firstMonday.add(Duration(days: index * 7));
        final weekEndDate = weekStartDate.add(const Duration(days: 6));
        
        // Check if current week
        final isCurrentWeek = today.isAfter(weekStartDate.subtract(const Duration(days: 1))) &&
                              today.isBefore(weekEndDate.add(const Duration(days: 1)));
        
        // Count total activities for the week
        int totalActivities = 0;
        for (int i = 0; i < 7; i++) {
          final date = weekStartDate.add(Duration(days: i));
          totalActivities += PlanStorage.loadPlansForDate(date).length;
        }
        
        // Get a sample of activities from the week
        final samplePlans = <dynamic>[];
        for (int i = 0; i < 7 && samplePlans.length < 3; i++) {
          final date = weekStartDate.add(Duration(days: i));
          final plans = PlanStorage.loadPlansForDate(date);
          for (final plan in plans) {
            if (samplePlans.length < 3) {
              samplePlans.add({'plan': plan, 'date': date});
            } else {
              break;
            }
          }
        }
        
        final dateRange = '${DateFormat('dd MMM').format(weekStartDate)} - ${DateFormat('dd MMM').format(weekEndDate)}';
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: isCurrentWeek ? Colors.deepPurple.shade50 : null,
          child: InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WeekDetailPage(
                    weekNumber: weekNumber,
                    startDate: weekStartDate,
                  ),
                ),
              );
              setState(() {});
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Week $weekNumber',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isCurrentWeek ? Colors.deepPurple.shade900 : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateRange,
                            style: TextStyle(
                              fontSize: 12,
                              color: isCurrentWeek ? Colors.deepPurple.shade700 : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$totalActivities',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: isCurrentWeek ? Colors.deepPurple.shade900 : Colors.grey,
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (samplePlans.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: samplePlans.map((item) {
                        final plan = item['plan'];
                        final date = item['date'] as DateTime;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  DateFormat('E').format(date),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(width: 6),
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
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  if (totalActivities > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        '+${totalActivities - 3} more activities this week',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  if (totalActivities == 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'No activities planned',
                        style: TextStyle(
                          fontSize: 14,
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
