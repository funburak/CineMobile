import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MovieScreen extends StatelessWidget {
  final Map<String, dynamic> movieDetails;

  const MovieScreen({Key? key, required this.movieDetails}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(movieDetails['title']),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (movieDetails['poster_path'] != null)
              Image.network(
                'https://image.tmdb.org/t/p/w500${movieDetails['poster_path']}',
                height: 300,
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 16),
            Text(
              movieDetails['title'],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Release Date: ${_formatDate(movieDetails['release_date'])}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              movieDetails['overview'] ?? 'No description available.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _showAddToListDialog(context, movieDetails['title']);
              },
              child: const Text('Add to List'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String date) {
    try {
      DateTime parsedDate = DateTime.parse(date); // Parse the date string
      return DateFormat('d MMMM yyyy')
          .format(parsedDate); // Format to "23 September 1994"
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<void> _addMovieToList(
      BuildContext context, String listName, String movieTitle) async {
    final prefs = await SharedPreferences.getInstance();

    List<String> movieList = prefs.getStringList(listName) ?? [];

    if (!movieList.contains(movieTitle)) {
      movieList.add(movieTitle);
      await prefs.setStringList(listName, movieList);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$movieTitle added to $listName')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$movieTitle is already in $listName')),
      );
    }
  }

  Future<void> _showAddToListDialog(
      BuildContext context, String movieTitle) async {
    final prefs = await SharedPreferences.getInstance();

    List<String> listNames = prefs.getStringList('listNames') ?? [];

    if (listNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No lists available. Create a list first.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              const Icon(Icons.playlist_add, color: Colors.deepPurpleAccent),
              const SizedBox(width: 8),
              const Text(
                'Select a List',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.deepPurpleAccent,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              children: listNames.map((listName) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    tileColor: Colors.deepPurple[50],
                    leading:
                        const Icon(Icons.list, color: Colors.deepPurpleAccent),
                    title: Text(
                      listName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () {
                      _addMovieToList(context, listName, movieTitle);
                      Navigator.pop(context);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.deepPurpleAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
