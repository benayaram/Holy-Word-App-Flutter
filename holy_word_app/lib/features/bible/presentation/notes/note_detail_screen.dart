import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For XFile in some versions if needed
import '../../services/notes_service.dart';
import 'share_note_screen.dart';

class NoteDetailScreen extends StatefulWidget {
  final int noteId;

  const NoteDetailScreen({super.key, required this.noteId});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  final NotesService _notesService = NotesService();

  Map<String, dynamic>? _noteData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNoteDetails();
  }

  Future<void> _loadNoteDetails() async {
    try {
      final data = await _notesService.getNoteDetails(widget.noteId);
      if (mounted) {
        setState(() {
          _noteData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading note: $e')),
        );
      }
    }
  }

  void _shareNoteAsImage() {
    if (_noteData == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShareNoteScreen(noteData: _noteData!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Note Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_noteData == null || _noteData!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Note Details')),
        body: const Center(child: Text('Note not found')),
      );
    }

    final title = _noteData!['title'];
    final content = _noteData!['content'];
    final verses = _noteData!['verses'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Note Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareNoteAsImage,
            tooltip: 'Share as Image',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateTime.parse(_noteData!['created_at'])
                  .toLocal()
                  .toString()
                  .split('.')[0],
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Content Section
            if (content != null && content.toString().isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Text(
                  content,
                  style: const TextStyle(fontSize: 16),
                ),
              ),

            const SizedBox(height: 24),
            const Text('Verses',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // Verses List
            ...verses.map((v) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v['reference'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        v['verse_text'],
                        style: const TextStyle(fontSize: 16, height: 1.4),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
