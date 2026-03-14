import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/plan_storage.dart';
import '../services/goal_storage.dart';
import '../models/plan.dart';
import '../models/goal.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onBackToOverview;

  const HomeScreen({super.key, this.onBackToOverview});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Plan> _todayPlans = [];
  Goal? _nextGoal;
  DateTime? _nextGoalDate;
  
  @override
  void initState() {
    super.initState();
    _loadTodayData();
  }

  void _loadTodayData() {
    final today = DateTime.now();
    final currentTime = DateTime.now();
    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    
    setState(() {
      final allPlans = PlanStorage.loadPlansForDate(today);
      
      // Filter to only show plans that haven't ended yet
      _todayPlans = allPlans.where((plan) {
        // If there's an end time, check if it hasn't passed yet
        if (plan.toTime != null) {
          final endMinutes = _timeToMinutes(plan.toTime!);
          return endMinutes >= currentMinutes;
        }
        // If no end time, check the start time
        if (plan.fromTime != null) {
          final startMinutes = _timeToMinutes(plan.fromTime!);
          return startMinutes >= currentMinutes;
        }
        // Show plans without time info
        return true;
      }).toList();
      
      final nextGoalData = GoalStorage.getNextGoal();
      if (nextGoalData != null) {
        _nextGoal = nextGoalData['goal'] as Goal;
        _nextGoalDate = nextGoalData['date'] as DateTime;
      } else {
        _nextGoal = null;
        _nextGoalDate = null;
      }
    });
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return 0;
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    return hours * 60 + minutes;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dateStr = DateFormat('EEEE, dd MMMM yyyy').format(today);

    return Column(
      children: [
        // Welcome Section - Takes 1/4 of the screen
        Container(
          height: MediaQuery.of(context).size.height * 0.25,
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
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: widget.onBackToOverview == null
                        ? const SizedBox(height: 48)
                        : IconButton(
                            onPressed: widget.onBackToOverview,
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            tooltip: 'Back to Overview',
                          ),
                  ),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Welcome to',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white70,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Domestique',
                            style: TextStyle(
                              fontSize: 42,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateStr,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Today's Overview Section - Rest of the screen
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    'Upcoming Today',
                    _todayPlans.length,
                    Icons.fitness_center,
                    Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  _todayPlans.isEmpty
                      ? _buildEmptyState(
                          'No upcoming plans',
                          'All done for today or visit Plan tab to add more',
                          Icons.directions_run,
                        )
                      : Column(
                          children: _todayPlans.asMap().entries.map((entry) {
                            final index = entry.key;
                            final plan = entry.value;
                            return _buildPlanCard(
                              context,
                              plan,
                              index,
                              Theme.of(context).colorScheme.primary,
                            );
                          }).toList(),
                        ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Icon(Icons.flag, color: Theme.of(context).colorScheme.secondary, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'Next Goal',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _nextGoal == null
                      ? _buildEmptyState(
                          'No goals',
                          'Go to Calendar tab to set your goals',
                          Icons.flag_outlined,
                        )
                      : _buildNextGoalCard(
                          context,
                          _nextGoal!,
                          _nextGoalDate!,
                          Theme.of(context).colorScheme.secondary,
                        ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count, IconData icon, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, Plan plan, int index, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            plan.toTime != null
                ? '${plan.fromTime ?? "--:--"}\n${plan.toTime}'
                : plan.fromTime ?? '--:--',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                plan.title ?? plan.description,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (plan.duration != null)
              Text(
                plan.duration!,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        subtitle: (plan.description.isNotEmpty && plan.description != plan.title)
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  plan.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildNextGoalCard(BuildContext context, Goal goal, DateTime date, Color color) {
    final today = DateTime.now();
    final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
    final dateStr = isToday ? 'Today' : DateFormat('EEEE, dd MMMM').format(date);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          backgroundColor: color,
          child: const Icon(
            Icons.flag,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          goal.description,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            dateStr,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}