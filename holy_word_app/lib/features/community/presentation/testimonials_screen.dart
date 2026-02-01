import 'package:flutter/material.dart';

class TestimonialsScreen extends StatefulWidget {
  const TestimonialsScreen({super.key});

  @override
  State<TestimonialsScreen> createState() => _TestimonialsScreenState();
}

class _TestimonialsScreenState extends State<TestimonialsScreen> {
  final List<Map<String, dynamic>> _testimonials = [
    {
      'author': 'Michael Brown',
      'title': 'Healed from Sickness',
      'content':
          'I want to thank God for healing me completely after the doctors gave up hope.',
      'date': 'Jan 28, 2024',
    },
    {
      'author': 'Emily Davis',
      'title': 'Financial Breakthrough',
      'content':
          'God provided for my family in a miraculous way when we were in debt.',
      'date': 'Jan 25, 2024',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Testimonials')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTestimonyDialog,
        icon: const Icon(Icons.add),
        label: const Text('Share Testimony'),
        backgroundColor: Colors.blue.shade100,
        foregroundColor: Colors.blue.shade900,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _testimonials.length,
        itemBuilder: (context, index) {
          final item = _testimonials[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child:
                            const Icon(Icons.format_quote, color: Colors.blue),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              'by ${item['author']} • ${item['date']}',
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
                    item['content'],
                    style: TextStyle(
                        color: Colors.grey[800], height: 1.5, fontSize: 15),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddTestimonyDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Testimony'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                labelText: 'Your Story',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (titleController.text.isNotEmpty &&
                  contentController.text.isNotEmpty) {
                setState(() {
                  _testimonials.insert(0, {
                    'author': 'You',
                    'title': titleController.text,
                    'content': contentController.text,
                    'date': 'Just now',
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }
}
