import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/notes_service.dart';
import '../../services/bible_service.dart';
import '../widgets/bible_picker_sheet.dart';
import 'share_note_screen.dart';
import '../bible_screen.dart';

class NoteDetailScreen extends ConsumerStatefulWidget {
  final int noteId;

  const NoteDetailScreen({super.key, required this.noteId});

  @override
  ConsumerState<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends ConsumerState<NoteDetailScreen> {
  final NotesService _notesService = NotesService();

  Map<String, dynamic>? _noteData;
  bool _isLoading = true;
  bool _isEditing = false;

  late TextEditingController _titleController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _loadNoteDetails();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadNoteDetails() async {
    try {
      final data = await _notesService.getNoteDetails(widget.noteId);
      if (mounted) {
        setState(() {
          _noteData = data;
          _isLoading = false;
          // Pre-fill controllers
          if (data.isNotEmpty) {
            _titleController.text = data['title'] ?? '';
            _contentController.text = data['content'] ?? '';
          }
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

  Future<void> _saveNote() async {
    try {
      await _notesService.updateNote(
        widget.noteId,
        _titleController.text,
        _contentController.text,
      );
      setState(() {
        _isEditing = false;
      });
      _loadNoteDetails(); // Reload to refresh view
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating note: $e')),
      );
    }
  }

  Future<void> _deleteVerse(int noteVerseId) async {
    try {
      await _notesService.removeVerseFromNote(noteVerseId);
      _loadNoteDetails(); // Refresh list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting verse: $e')),
      );
    }
  }

  Future<void> _addVerse() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BiblePickerSheet(
        initialBookId: 1,
        initialChapter: 1,
        initialVerse: 1,
        enableVerseSelection: true,
        onSelectionChanged: (bookId, chapter, verse, language) async {
          // Fetch verse text using the selected language
          // We need to fetch specific language text. getVerseForSelection has optional `language`.
          try {
            final bibleService = ref.read(bibleServiceProvider);
            final verseData = await bibleService.getVerseForSelection(
                bookId, chapter, verse,
                language: language == 'telugu'
                    ? 'Telugu'
                    : 'English'); // service expects capitalized 'Telugu'/'English' or specific code?
            // Checking BibleService.getVerseForSelection implementation...
            // It accepts 'Telugu', 'English', 'Both'.
            // Our picker returns 'telugu'/'english' lowercase.
            // Let's capitalize.

            if (verseData.isNotEmpty) {
              // Add to note
              await _notesService.addVerseToNote(
                widget.noteId,
                bookId,
                chapter,
                verse,
                verseData['text'],
                verseData['reference'],
              );
              _loadNoteDetails();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Verse added to note')),
                );
              }
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error adding verse: $e')),
              );
            }
          }
        },
      ),
    );
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

  Future<void> _shareNoteText() async {
    if (_noteData == null) return;

    final StringBuffer sb = StringBuffer();
    sb.writeln(_noteData!['title'] ?? 'Untitled Note');
    sb.writeln('----------------');
    sb.writeln(_noteData!['content'] ?? '');
    sb.writeln();

    final verses = _noteData!['verses'] as List<dynamic>? ?? [];
    if (verses.isNotEmpty) {
      sb.writeln('Verses:');
      for (var v in verses) {
        sb.writeln('${v['reference']}');
        sb.writeln('${v['verse_text']}');
        sb.writeln();
      }
    }

    await Share.share(sb.toString());
  }

  Future<void> _confirmDeleteNote() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text(
            'Are you sure you want to delete this note and all its content?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      try {
        await _notesService.deleteNoteV2(widget.noteId);
        if (mounted) {
          Navigator.pop(context); // Go back to list
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Note deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting note: $e')),
          );
        }
      }
    }
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

    final verses = _noteData!['verses'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Note Details'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _saveNote();
              } else {
                setState(() {
                  _isEditing = true;
                });
              }
            },
            tooltip: _isEditing ? 'Save Changes' : 'Edit Note',
          ),
          if (!_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.description), // Text icon
              onPressed: _shareNoteText,
              tooltip: 'Share as Text',
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareNoteAsImage,
              tooltip: 'Share as Image',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDeleteNote,
              tooltip: 'Delete Note',
            ),
          ]
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isEditing)
              TextField(
                controller: _titleController,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              )
            else
              Text(
                _noteData!['title'],
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
            if (_isEditing)
              TextField(
                controller: _contentController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              )
            else if (_noteData!['content'] != null &&
                _noteData!['content'].toString().isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Text(
                  _noteData!['content'],
                  style: const TextStyle(fontSize: 16),
                ),
              ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Verses',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (_isEditing)
                  TextButton.icon(
                    onPressed: _addVerse,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Verse'),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Verses List
            ...verses.map((v) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Stack(
                  children: [
                    InkWell(
                      onTap: () {
                        if (v['book_id'] != null &&
                            v['chapter'] != null &&
                            v['verse'] != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BibleScreen(
                                initialBookId: v['book_id'],
                                initialChapter: v['chapter'],
                                initialVerse: v['verse'],
                              ),
                            ),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
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
                    ),
                    if (_isEditing)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteVerse(v['id']),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
