import 'package:flutter/material.dart';

class PrayerWallScreen extends StatefulWidget {
  const PrayerWallScreen({super.key});

  @override
  State<PrayerWallScreen> createState() => _PrayerWallScreenState();
}

class _PrayerWallScreenState extends State<PrayerWallScreen> {
  final List<Map<String, dynamic>> _prayers = [
    {
      'author': 'John Doe',
      'content':
          'Please pray for my mother who is undergoing surgery tomorrow.',
      'time': '2 hours ago',
      'prayed_count': 12,
      'is_prayed': false,
    },
    {
      'author': 'Sarah Smith',
      'content': 'Praying for guidance in my career decisions.',
      'time': '5 hours ago',
      'prayed_count': 8,
      'is_prayed': true,
    },
    {
      'author': 'David Wilson',
      'content': 'Thanksgiving for a safe trip home.',
      'time': '1 day ago',
      'prayed_count': 24,
      'is_prayed': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prayer Wall')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPrayerDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Request'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _prayers.length,
        itemBuilder: (context, index) {
          final prayer = _prayers[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.orange.shade100,
                        child: Text(
                          (prayer['author'] as String)[0],
                          style: TextStyle(color: Colors.orange.shade800),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prayer['author'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              prayer['time'],
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    prayer['content'],
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${prayer['prayed_count']} Praying',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            if (prayer['is_prayed']) {
                              prayer['prayed_count']--;
                              prayer['is_prayed'] = false;
                            } else {
                              prayer['prayed_count']++;
                              prayer['is_prayed'] = true;
                            }
                          });
                        },
                        icon: Icon(
                          prayer['is_prayed']
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: prayer['is_prayed'] ? Colors.red : Colors.grey,
                        ),
                        label: Text(
                          prayer['is_prayed'] ? 'Prayed' : 'Pray',
                          style: TextStyle(
                            color:
                                prayer['is_prayed'] ? Colors.red : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddPrayerDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Prayer Request'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Share your prayer request...',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _prayers.insert(0, {
                    'author': 'You',
                    'content': controller.text,
                    'time': 'Just now',
                    'prayed_count': 0,
                    'is_prayed': false,
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }
}
