import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/bible_service.dart';

class BibleSearchDelegate extends SearchDelegate<Map<String, dynamic>?> {
  final WidgetRef ref;

  BibleSearchDelegate(this.ref);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Enter a search term'));
    }

    // This is a placeholder for actual search logic.
    // In a real app with Supabase, we would call a search RPC or use text search.
    // For now, let's just show a message or mock results if possible,
    // or implement a basic search service method if Supabase supports it easily.

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _searchBible(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No results found'));
        }

        final results = snapshot.data!;
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final result = results[index];
            return ListTile(
              title: Text(
                  '${result['book_name']} ${result['chapter']}:${result['verse']}'),
              subtitle: Text(result['text']),
              onTap: () {
                close(context, result);
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: const Text('Search for "Love"'),
          onTap: () {
            query = 'Love';
            showResults(context);
          },
        ),
        ListTile(
          title: const Text('Search for "Jesus"'),
          onTap: () {
            query = 'Jesus';
            showResults(context);
          },
        ),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> _searchBible(String query) async {
    final bibleService = ref.read(bibleServiceProvider);
    return bibleService.searchVerses(query);
  }
}
