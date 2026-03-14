import 'package:flutter/material.dart';
import 'finance_page.dart';
import 'main_screen.dart';
import 'todo_page.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  final List<_Vertical> _verticals = [
    _Vertical('To Do List', Icons.checklist, 0),
    _Vertical('Training Plan', Icons.fitness_center, 0),
    _Vertical('My Financial Situation', Icons.account_balance_wallet, 2),
  ];

  void _addVertical() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Vertical'),
        content: const Text('Feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _openVertical(_Vertical vertical) {
    if (vertical.title == 'To Do List') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TodoPage()),
      );
      return;
    }

    if (vertical.title == 'My Financial Situation') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FinancePage()),
      );
      return;
    }

    if (vertical.mainScreenTabIndex != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MainScreen(initialTab: vertical.mainScreenTabIndex!),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${vertical.title}" is not implemented yet.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Overview'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.05,
          children: [
            ..._verticals.map((vertical) => _buildTile(
                  icon: vertical.icon,
                  title: vertical.title,
                  onTap: () => _openVertical(vertical),
                )),
            _buildTile(
              icon: Icons.add_circle_outline,
              title: 'Add Vertical',
              onTap: _addVertical,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 38, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Vertical {
  final String title;
  final IconData icon;
  final int? mainScreenTabIndex;
  _Vertical(this.title, this.icon, this.mainScreenTabIndex);
}
