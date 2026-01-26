import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PlanCalendarView extends StatefulWidget {
  final List<Map<String, dynamic>> progress;
  final int totalDays;
  final Function(int) onDaySelected;

  const PlanCalendarView({
    super.key,
    required this.progress,
    required this.totalDays,
    required this.onDaySelected,
  });

  @override
  State<PlanCalendarView> createState() => _PlanCalendarViewState();
}

class _PlanCalendarViewState extends State<PlanCalendarView> {
  DateTime _focusedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    // 1. Infer Start Date
    // Default to Jan 1st of current year if no progress
    DateTime planStartDate = DateTime(DateTime.now().year, 1, 1);

    if (widget.progress.isNotEmpty) {
      // Logic Fix: Prioritize Day 0 (First Day) to anchor the Start Date.
      // If user read Day 0, that IS the start date.
      // If Day 0 is not read yet, fall back to the earliest implied start.

      final day0 = widget.progress.firstWhere(
        (p) => p['day_index'] == 0 && p['is_completed'] == 1,
        orElse: () => {},
      );

      if (day0.isNotEmpty && day0['completed_date'] != null) {
        final d = DateTime.parse(day0['completed_date']);
        planStartDate = DateTime(d.year, d.month, d.day);
      } else {
        // Fallback: Find min implied start
        DateTime? minImpliedStart;
        for (var p in widget.progress) {
          if (p['completed_date'] != null) {
            final completedDate = DateTime.parse(p['completed_date']);
            // dayIdx unused

            // Only consider "implied start" if it doesn't push start date into the future relative to "now"
            // Actually, usually we assume start date is somewhat fixed.
            // Let's us the EARLIEST Completed Date as the Start Date?
            // No, that fails if I start with Day 5.

            // Revert to "Simple" logic: The plan started on the day of the FIRST interaction?
            // Or stick to "Implied" but cap it?

            // Let's stick to "Min Implied" but only from the *earliest* completed record?
            // No, complex.

            // Best Guess: Use the earliest recorded completion actual date.
            // If I read Day 1 on Jan 26, Start = Jan 26.
            // If I read Day 2 on Jan 26, that is just "Early". Start is still Jan 26.
            // So: StartDate = min(all completed_dates).

            if (minImpliedStart == null ||
                completedDate.isBefore(minImpliedStart)) {
              minImpliedStart = completedDate;
            }
          }
        }
        if (minImpliedStart != null) {
          planStartDate = DateTime(
              minImpliedStart.year, minImpliedStart.month, minImpliedStart.day);
        }
      }
    }

    final daysInMonth =
        DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    final firstDayOfMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final offset = firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _focusedMonth =
                        DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                  });
                },
              ),
              Column(
                children: [
                  Text(
                    DateFormat('MMMM yyyy').format(_focusedMonth),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (widget.progress.isNotEmpty)
                    Text(
                      "Started: ${DateFormat.yMMMd().format(planStartDate)}",
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    )
                ],
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _focusedMonth =
                        DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                  });
                },
              ),
            ],
          ),
        ),

        // Days Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map((d) => Text(d,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey)))
              .toList(),
        ),
        const SizedBox(height: 12),

        // Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: daysInMonth + offset,
            itemBuilder: (context, index) {
              if (index < offset) return const SizedBox.shrink();

              final dayNum = index - offset + 1;
              final date =
                  DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);

              // Calculate target Plan Day Index based on Start Date
              final diff = date.difference(planStartDate).inDays;
              final planDayIndex = diff; // 0-based

              if (planDayIndex < 0) {
                // Check if it's "Today" even if before program start (weird edge case)
                final isToday = DateTime.now().year == date.year &&
                    DateTime.now().month == date.month &&
                    DateTime.now().day == date.day;
                return Container(
                  decoration: isToday
                      ? BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Theme.of(context).primaryColor, width: 2),
                        )
                      : null,
                  child: Center(
                    child: Text('$dayNum',
                        style: TextStyle(color: Colors.grey[300])),
                  ),
                );
              }

              if (planDayIndex >= widget.totalDays) {
                return const SizedBox.shrink();
              }

              return _buildDayCell(date, planDayIndex, dayNum);
            },
          ),
        ),
        // Legend
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _LegendItem(color: Colors.teal, label: "Early"),
              _LegendItem(color: Colors.green, label: "On Time"),
              _LegendItem(color: Colors.orange, label: "Late"),
              _LegendItem(color: Colors.grey, label: "Missed"),
            ],
          ),
        ),
      ],
    ); // Explicitly closing Column to match structure
  }

  // Need to verify where _buildDayCell is relative to this content.
  // IMPORTANT: The target range for replacement is lines 23-172 (build method).
  // The tool needs the StartLine/EndLine to be accurate.

  Widget _buildDayCell(DateTime date, int planDayIndex, int dayNum) {
    // Find progress for this Plan Day Index
    final pEntry = widget.progress.firstWhere(
      (p) => p['day_index'] == planDayIndex && p['is_completed'] == 1,
      orElse: () => {},
    );

    final isCompleted = pEntry.isNotEmpty;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = date.isAtSameMomentAs(today);

    Color bgColor = Colors.transparent;
    Color textColor = Colors.black87;
    BoxBorder? border;

    if (isCompleted) {
      textColor = Colors.white;
      // Determine Late/OnTime/Early
      final completedStr = pEntry['completed_date'] as String?;
      if (completedStr != null) {
        final completedDate = DateTime.parse(completedStr);
        final completedDateOnly = DateTime(
            completedDate.year, completedDate.month, completedDate.day);

        // Schedule Date for this index is `date` (from Grid)
        // Completed Date is `completedDateOnly`

        if (completedDateOnly.isBefore(date)) {
          // Completed BEFORE the scheduled date -> Early
          // User Request: "teal green with opacity low"
          bgColor = Colors.teal.withOpacity(0.6);
        } else if (completedDateOnly.isAfter(date)) {
          bgColor = Colors.orange.shade400; // Late
        } else {
          bgColor = Colors.green; // On Time
        }
      } else {
        bgColor = Colors.green;
      }

      // If completed TODAY, maybe add a border? Or just rely on IsToday logic below?
      // User said "current date need to be like Border color".
      if (isToday) {
        border = Border.all(color: Theme.of(context).primaryColor, width: 3);
      }
    } else {
      // Not Completed
      if (date.isBefore(today)) {
        // Missed (Past)
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade600;
      } else if (isToday) {
        // Today (Due)
        border = Border.all(color: Theme.of(context).primaryColor, width: 2);
        textColor = Theme.of(context).primaryColor;
      }
    }

    return InkWell(
      onTap: () => widget.onDaySelected(planDayIndex),
      customBorder: const CircleBorder(),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: border,
          boxShadow: isCompleted
              ? [
                  BoxShadow(
                      color: bgColor.withOpacity(0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ]
              : null,
        ),
        child: Center(
          child: Text(
            '$dayNum',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 12)),
    ]);
  }
}
