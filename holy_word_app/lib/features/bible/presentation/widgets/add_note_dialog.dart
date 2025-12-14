import 'package:flutter/material.dart';
import '../../services/notes_service.dart';

class AddNoteDialog extends StatefulWidget {
  final Map<String, dynamic>
      verseData; // Includes text, reference, bookId, chapter, verse
  final VoidCallback onSuccess;

  const AddNoteDialog({
    super.key,
    required this.verseData,
    required this.onSuccess,
  });

  @override
  State<AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<AddNoteDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NotesService _notesService = NotesService();

  // New Note Controller
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  // Existing Note State
  List<Map<String, dynamic>> _existingNotes = [];
  int? _selectedNoteId;
  bool _isLoadingNotes = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadExistingNotes();
  }

  Future<void> _loadExistingNotes() async {
    final notes = await _notesService.getNotesV2();
    if (mounted) {
      setState(() {
        _existingNotes = notes;
        _isLoadingNotes = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNewNote() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    try {
      final noteId = await _notesService.createNote(
        _titleController.text,
        _contentController.text,
      );

      await _addToNote(noteId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating note: $e')),
      );
    }
  }

  Future<void> _addToExistingNote() async {
    if (_selectedNoteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a note')),
      );
      return;
    }
    try {
      await _addToNote(_selectedNoteId!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding to note: $e')),
      );
    }
  }

  Future<void> _addToNote(int noteId) async {
    await _notesService.addVerseToNote(
      noteId,
      widget.verseData['book_id'],
      widget.verseData['chapter'],
      widget.verseData['verse'],
      widget.verseData['text'],
      widget.verseData['reference'],
    );

    if (mounted) {
      widget.onSuccess();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Center(
              child: Text(
                'Add to Note',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'New Note'),
              Tab(text: 'Existing Note'),
            ],
          ),

          // Content
          SizedBox(
            height: 300,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNewNoteTab(),
                _buildExistingNoteTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewNoteTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              hintText: 'My Study, Sermon Notes, etc.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Note Content (Optional)',
                hintText: 'Enter your thoughts...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saveNewNote,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Create & Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildExistingNoteTab() {
    if (_isLoadingNotes) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_existingNotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.note_alt_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No notes found.'),
            TextButton(
              onPressed: () => _tabController.animateTo(0),
              child: const Text('Create New'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _existingNotes.length,
              itemBuilder: (context, index) {
                final note = _existingNotes[index];
                final isSelected = _selectedNoteId == note['id'];
                return Card(
                  elevation: isSelected ? 4 : 1,
                  color: isSelected ? Colors.blue.shade50 : Colors.white,
                  child: ListTile(
                    title: Text(note['title'],
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        note['content'] != null &&
                                note['content'].toString().isNotEmpty
                            ? note['content']
                            : 'No content',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.blue)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedNoteId = note['id'];
                      });
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _addToExistingNote,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Add to Selected Note'),
          ),
        ],
      ),
    );
  }
}
