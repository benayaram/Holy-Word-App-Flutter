import 'package:flutter/material.dart';

class EventCalendarScreen extends StatelessWidget {
  const EventCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Event Calendar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'Upcoming Events',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          _buildEventCard(
            context,
            day: '05',
            month: 'FEB',
            title: 'Youth Worship Night',
            time: '6:00 PM - 8:30 PM',
            location: 'Main Sanctuary',
            color: Colors.orange,
          ),
          _buildEventCard(
            context,
            day: '12',
            month: 'FEB',
            title: 'Community Bible Study',
            time: '7:00 PM - 8:30 PM',
            location: 'Fellowship Hall',
            color: Colors.blue,
          ),
          _buildEventCard(
            context,
            day: '14',
            month: 'FEB',
            title: 'Valentines Couple Dinner',
            time: '5:30 PM - 9:00 PM',
            location: 'Grand Ball Room',
            color: Colors.pink,
          ),
          _buildEventCard(
            context,
            day: '20',
            month: 'FEB',
            title: 'Worship Concert',
            time: '6:00 PM - 10:00 PM',
            location: 'Open Grounds',
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(
    BuildContext context, {
    required String day,
    required String month,
    required String title,
    required String time,
    required String location,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Text(
                    day,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    month,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        time,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
