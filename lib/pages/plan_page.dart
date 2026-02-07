import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'day_detail_page.dart';
import '../services/plan_storage.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  String _selectedView = 'Week';
  final List<String> _viewOptions = ['Week', 'Month'];
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

  @override
  Widget build(BuildContext context) {
    return Padding(
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
          color: isToday ? Colors.deepPurple.shade100 : null,
          child: ListTile(
            title: Text(
              _weekDays[index],
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isToday ? Colors.deepPurple.shade900 : null,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                '$dateStr - ${dayPlans.isEmpty ? "No tasks yet" : "${dayPlans.length} task(s)"}',
                style: TextStyle(
                  color: isToday ? Colors.deepPurple.shade700 : null,
                ),
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: isToday ? Colors.deepPurple.shade900 : null,
            ),
            onTap: () => _navigateToDay(_weekDays[index], null, date),
          ),
        );
      },
    );
  }

  Widget _buildMonthView() {
    final today = DateTime.now();
    final currentDay = today.day;
    final currentMonth = today.month;
    final currentYear = today.year;
    final daysInMonth = DateTime(currentYear, currentMonth + 1, 0).day;

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: daysInMonth,
      itemBuilder: (context, index) {
        final dayNumber = index + 1;
        final isToday = dayNumber == currentDay;
        final date = _getDateForMonthDay(dayNumber);
        
        return InkWell(
          onTap: () => _navigateToDay('Day', dayNumber, date),
          child: Card(
            color: isToday ? Colors.deepPurple.shade100 : null,
            child: Center(
              child: Text(
                '$dayNumber',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isToday ? Colors.deepPurple.shade900 : null,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
