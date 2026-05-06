import 'package:flutter/material.dart';
import '../../services/reading_plan_service.dart';
import '../../../../core/services/notification_service.dart';
import 'plan_read_screen.dart';
import 'plan_calendar_view.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class PlanDetailScreen extends StatefulWidget {
  final String planId;
  final String planName;

  const PlanDetailScreen(
      {super.key, required this.planId, required this.planName});

  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen> {
  final ReadingPlanService _planService = ReadingPlanService();

  bool _isLoading = true;
  Map<String, dynamic>? _planData;
  List<Map<String, dynamic>> _progress = [];
  int _completedDays = 0;
  int _totalDays = 365;
  int _nextUnreadDay = 0; // 0-based index
  int _currentStreak = 0;
  // Reminder State
  List<ReminderModel> _reminders = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _refreshReminders();
  }

  Future<void> _refreshReminders() async {
    final ns = NotificationService();
    final list = await ns.getRemindersForPlan(widget.planId);
    if (mounted) {
      setState(() {
        _reminders = list;
      });
    }
  }

  Future<void> _handleNotificationPress() async {
    final ns = NotificationService();
    // Check permission first
    final granted = await ns.requestPermissions();
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notification permission denied')));
      }
      return;
    }

    if (!mounted) return;

    // Show Reminder Manager Bottom Sheet
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              // Use constrained height or allow scrolling to prevent overflow
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Daily Reminders',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle,
                            color: Colors.blue, size: 30),
                        onPressed: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (picked != null) {
                            await ns.addReminder(widget.planId, picked);
                            // Refresh both modal list and parent screen state
                            final newList =
                                await ns.getRemindersForPlan(widget.planId);
                            setModalState(() {
                              _reminders = newList;
                            });
                            _refreshReminders(); // Refresh parent too
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: _reminders.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                                child: Text("No reminders set for this plan.")),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: _reminders.length,
                            itemBuilder: (context, index) {
                              final r = _reminders[index];
                              final timeStr =
                                  TimeOfDay(hour: r.hour, minute: r.minute)
                                      .format(context);

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.alarm,
                                    color: Colors.orange),
                                title: Text(timeStr,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.grey),
                                  onPressed: () async {
                                    await ns.deleteReminder(r.id);
                                    final newList = await ns
                                        .getRemindersForPlan(widget.planId);
                                    setModalState(() {
                                      _reminders = newList;
                                    });
                                    _refreshReminders();
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Done"),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load Plan Data (JSON)
      final plan = await _planService.loadPlan(widget.planId);
      final rawData = plan['data'] as List<dynamic>?;
      final rawData2 = plan['data2'] as List<dynamic>?;

      int total = 0;
      if (rawData2 != null) {
        total = rawData2.length;
      } else if (rawData != null) total = rawData.length;

      // Load Progress (DB)
      final progressList = await _planService.getPlanProgress(widget.planId);

      // Determine Next Unread
      final nextDay = await _planService.getNextUnreadDayIndex(widget.planId);

      // Calculate Streak
      final streak = await _planService.getCurrentStreak(widget.planId);

      setState(() {
        _planData = plan;
        _totalDays = total;
        _progress = progressList;
        _completedDays =
            progressList.where((p) => p['is_completed'] == 1).length;
        _nextUnreadDay = nextDay;
        _currentStreak = streak;
      });
    } catch (e) {
      debugPrint('Error loading plan detail: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isDayCompleted(int index) {
    return _progress
        .any((p) => p['day_index'] == index && p['is_completed'] == 1);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_planData == null) {
      return const Scaffold(body: Center(child: Text('Failed to load plan')));
    }

    // Calculate Progress
    final double percent = _totalDays > 0 ? _completedDays / _totalDays : 0;

    // Check if this plan has reminders
    bool hasActiveReminders = _reminders.isNotEmpty;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.planName),
          actions: [
            IconButton(
              icon: Icon(hasActiveReminders
                  ? Icons.notifications_active
                  : Icons.notifications_none),
              color: hasActiveReminders ? Colors.orange : null,
              onPressed: _handleNotificationPress,
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: "List"),
              Tab(text: "Calendar"),
            ],
          ),
        ),
        body: Column(
          children: [
            // ... Rest of UI ... implementation unchanged until next method
            // Dashboard Header (Always Visible)
            Container(
              padding: const EdgeInsets.all(20),
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Progress',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text('${(percent * 100).toInt()}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      // Streak Display
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Streak',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text('$_currentStreak',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange)),
                              const SizedBox(width: 4),
                              const Text('🔥', style: TextStyle(fontSize: 20)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                      value: percent,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5)),
                  const SizedBox(height: 20),

                  // Smart "Continue" Button (Catch Up)
                  if (_nextUnreadDay < _totalDays)
                    ElevatedButton.icon(
                      onPressed: () => _openDay(_nextUnreadDay),
                      icon: const Icon(Icons.play_arrow),
                      label: Text(
                          'Continue Day ${_nextUnreadDay + 1}'), // Display 1-based
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    )
                  else
                    const Card(
                      color: Colors.green,
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text('Plan Completed! 🎉',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                children: [
                  // List View
                  ScrollablePositionedList.builder(
                    itemCount: _totalDays,
                    initialScrollIndex: _nextUnreadDay > 0 ? _nextUnreadDay : 0,
                    itemBuilder: (context, index) {
                      final isCompleted = _isDayCompleted(index);
                      final isNext = index == _nextUnreadDay;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isCompleted
                              ? Colors.green
                              : (isNext ? Colors.orange : Colors.grey[300]),
                          child: isCompleted
                              ? const Icon(Icons.check, color: Colors.white)
                              : Text('${index + 1}',
                                  style: TextStyle(
                                      color: isNext
                                          ? Colors.white
                                          : Colors.black)),
                        ),
                        title: Text('Day ${index + 1}'),
                        subtitle: _buildReadingsPreview(index),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _openDay(index),
                      );
                    },
                  ),

                  // Calendar View
                  PlanCalendarView(
                    progress: _progress,
                    totalDays: _totalDays,
                    onDaySelected: (index) => _openDay(index),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingsPreview(int dayIndex) {
    if (_planData == null) return const SizedBox.shrink();

    // mcheyne specific: data2 is array of arrays
    final data2 = _planData!['data2'] as List<dynamic>?;
    if (data2 != null && dayIndex < data2.length) {
      final readings = data2[dayIndex] as List<dynamic>;
      // Just show first 2
      final preview = readings.take(2).map((e) => e.toString()).join(', ');
      return Text(preview + (readings.length > 2 ? '...' : ''),
          maxLines: 1, overflow: TextOverflow.ellipsis);
    }
    return const SizedBox.shrink();
  }

  void _openDay(int dayIndex) async {
    // Get Readings for this day
    final data2 = _planData!['data2'] as List<dynamic>?;
    if (data2 == null || dayIndex >= data2.length) return;

    final readings = List<String>.from(data2[dayIndex]);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlanReadScreen(
          planId: widget.planId,
          dayIndex: dayIndex,
          readings: readings,
        ),
      ),
    );

    // Reload Progress on return
    _loadData();
  }
}
