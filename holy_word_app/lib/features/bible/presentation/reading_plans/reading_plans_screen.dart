import 'package:flutter/material.dart';
import '../../services/reading_plan_service.dart';
import 'plan_detail_screen.dart';

class ReadingPlansScreen extends StatefulWidget {
  const ReadingPlansScreen({super.key});

  @override
  State<ReadingPlansScreen> createState() => _ReadingPlansScreenState();
}

class _ReadingPlansScreenState extends State<ReadingPlansScreen> {
  final ReadingPlanService _planService = ReadingPlanService();
  final Map<String, bool> _planStartedStatus = {};

  final List<Map<String, dynamic>> _plans = [
    {
      'id': 'mcheyne',
      'name': "M'Cheyne Reading Plan",
      'description': 'Read the OT once and NT/Psalms twice in a year.',
      'days': 365,
    },
    {
      'id': 'backtothebiblechronological',
      'name': "Chronological Plan",
      'description': 'Read the Bible in the order events occurred.',
      'days': 365,
    },
    {
      'id': 'oneyearchronological',
      'name': "One Year Chronological",
      'description': 'Default One Year Chronological Plan.',
      'days': 365,
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkPlanStatuses();
  }

  Future<void> _checkPlanStatuses() async {
    for (var plan in _plans) {
      final id = plan['id'] as String;
      final progress = await _planService.getPlanProgress(id);
      // Check if any day is marked completed
      final hasBroadProgres = progress.any((p) => p['is_completed'] == 1);
      if (mounted) {
        setState(() {
          _planStartedStatus[id] = hasBroadProgres;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reading Plans')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _plans.length,
        itemBuilder: (context, index) {
          final plan = _plans[index];
          final id = plan['id'] as String;
          final isStarted = _planStartedStatus[id] ?? false;

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: isStarted
                          ? Colors.orange.shade100
                          : Colors.blue.shade50,
                      child: Icon(Icons.calendar_today,
                          color: isStarted ? Colors.orange : Colors.blue),
                    ),
                    title: Text(plan['name'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(plan['description'] as String),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isStarted) ...[
                        Text("In Progress ",
                            style: TextStyle(
                                color: Colors.orange.shade800,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        // Reset Button
                        TextButton(
                          onPressed: () => _confirmReset(plan),
                          style:
                              TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Reset'),
                        ),
                        const SizedBox(width: 8),
                      ],
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isStarted
                              ? Colors.orange
                              : Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () {
                          _navigateToPlan(plan);
                        },
                        child: Text(isStarted ? 'Continue' : 'Start Plan'),
                      )
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmReset(Map<String, dynamic> plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Plan?'),
        content: Text(
            'This will delete all progress for "${plan['name']}". This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _planService.resetPlanProgress(plan['id']);
              _checkPlanStatuses(); // Refresh UI
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _navigateToPlan(Map<String, dynamic> plan) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlanDetailScreen(
          planId: plan['id'] as String,
          planName: plan['name'] as String,
        ),
      ),
    );
    // Refresh status when returning
    _checkPlanStatuses();
  }
}
