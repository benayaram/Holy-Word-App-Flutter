import 'package:flutter/material.dart';
import 'package:holy_word_app/features/bible/services/notes_service.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final NotesService _notesService = NotesService();
  late Future<List<Map<String, dynamic>>> _notesFuture;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _loadNotes() {
    setState(() {
      _notesFuture = _notesService.getNotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notes'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _notesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No notes yet', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final notes = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            note['reference'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20),
                            onPressed: () async {
                              await _notesService.deleteNote(note['id']);
                              _loadNotes();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        note['verse_text'],
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (note['note_content'] != null &&
                          note['note_content'].toString().isNotEmpty) ...[
                        const Divider(height: 24),
                        Text(note['note_content']),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
