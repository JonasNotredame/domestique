import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'day_detail_page.dart';
import '../services/plan_storage.dart';

class WeekDetailPage extends StatefulWidget {
  final int weekNumber;
  final DateTime startDate;

  const WeekDetailPage({
    super.key,
    required this.weekNumber,
    required this.startDate,
  });

  @override
  State<WeekDetailPage> createState() => _WeekDetailPageState();
}

class _WeekDetailPageState extends State<WeekDetailPage> {
  final List<String> _weekDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  DateTime _getDateForDay(int dayIndex) {
    return widget.startDate.add(Duration(days: dayIndex));
  }

  Future<void> _navigateToDay(String dayName, DateTime date) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DayDetailPage(
          dayName: dayName,
          dayNumber: date.day,
          date: date,
        ),
      ),
    );
    // Refresh after returning
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final endDate = widget.startDate.add(const Duration(days: 6));
    final dateRange = '${DateFormat('dd MMM').format(widget.startDate)} - ${DateFormat('dd MMM').format(endDate)}';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Week ${widget.weekNumber}'),
            Text(
              dateRange,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: _weekDays.length,
          itemBuilder: (context, index) {
            final date = _getDateForDay(index);
            final today = DateTime.now();
            final isToday = date.year == today.year && 
                           date.month == today.month && 
                           date.day == today.day;
            final dateStr = DateFormat('dd/MM/yyyy').format(date);
            final dayPlans = PlanStorage.loadPlansForDate(date);
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: isToday ? Colors.deepPurple.shade50 : null,
              child: InkWell(
                onTap: () => _navigateToDay(_weekDays[index], date),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                _weekDays[index],
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isToday ? Colors.deepPurple.shade900 : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${date.day}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isToday ? Colors.deepPurple.shade700 : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${dayPlans.length} activities',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
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
        ),
      ),
    );
  }
}
