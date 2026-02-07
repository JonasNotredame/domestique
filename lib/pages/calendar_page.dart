import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'day_detail_page.dart';
import '../services/plan_storage.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  Future<void> _navigateToDay(DateTime date) async {
    final dayName = DateFormat('EEEE').format(date);
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

  int _getEventCount(DateTime day) {
    final plans = PlanStorage.loadPlansForDate(day);
    return plans.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0, top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      final today = DateTime.now();
                      setState(() {
                        _focusedDay = today;
                        _selectedDay = today;
                        _selectedYear = today.year;
                        _selectedMonth = today.month;
                      });
                    },
                    icon: const Icon(Icons.today, size: 20),
                    label: const Text('Today'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
                        _selectedMonth = _focusedDay.month;
                        _selectedYear = _focusedDay.year;
                      });
                    },
                  ),
                  Text(
                    DateFormat('MMMM').format(_focusedDay),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: _selectedYear,
                    underline: Container(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    items: List.generate(11, (index) => 2020 + index).map((year) {
                      return DropdownMenuItem<int>(
                        value: year,
                        child: Text('$year'),
                      );
                    }).toList(),
                    onChanged: (year) {
                      if (year != null) {
                        setState(() {
                          _selectedYear = year;
                          _focusedDay = DateTime(year, _selectedMonth, 1);
                        });
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      setState(() {
                        _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
                        _selectedMonth = _focusedDay.month;
                        _selectedYear = _focusedDay.year;
                      });
                    },
                  ),
                ],
              ),
            ),
            TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Month',
            },
            onDaySelected: (selectedDay, focusedDay) {
              if (!isSameDay(_selectedDay, selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                  _selectedYear = focusedDay.year;
                  _selectedMonth = focusedDay.month;
                });
                _navigateToDay(selectedDay);
              }
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
                _selectedYear = focusedDay.year;
                _selectedMonth = focusedDay.month;
              });
            },
            headerVisible: false,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                shape: BoxShape.circle,
              ),
              weekendTextStyle: TextStyle(
                color: Colors.red[400],
              ),
              outsideDaysVisible: true,
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                final eventCount = _getEventCount(date);
                if (eventCount > 0) {
                  return Positioned(
                    bottom: 1,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$eventCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _selectedDay != null
                ? _buildSelectedDayEvents()
                : const Center(
                    child: Text('Select a day to view events'),
                  ),
          ),
        ],
      ),
      ),
      floatingActionButton: _selectedDay != null
          ? FloatingActionButton(
              onPressed: () => _navigateToDay(_selectedDay!),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildSelectedDayEvents() {
    final plans = PlanStorage.loadPlansForDate(_selectedDay!);
    final dateStr = DateFormat('EEEE, dd MMMM yyyy').format(_selectedDay!);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateStr,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${plans.length} event(s)',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: plans.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No events',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: plans.length,
                    itemBuilder: (context, index) {
                      final plan = plans[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(plan.description),
                          subtitle: Text(
                            DateFormat('HH:mm').format(plan.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
