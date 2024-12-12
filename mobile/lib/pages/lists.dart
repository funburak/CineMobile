import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logging/logging.dart';

class ListsPage extends StatefulWidget {
  const ListsPage({super.key});

  @override
  _ListsPageState createState() => _ListsPageState();
}

class _ListsPageState extends State<ListsPage> {
  List<Map<String, dynamic>> lists = [];  // List of lists and their movies
  bool isLoading = false;
  String apiKey = 'YOUR_API_KEY';  // Replace with your TMDb API key
  final Logger logger = Logger('ListsPage');

  @override
  void initState() {
    super.initState();
    _loadLists();  // Load lists from SharedPreferences
  }

  // Load lists from SharedPreferences
  Future<void> _loadLists() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> listNames = prefs.getStringList('listNames') ?? [];

    List<Map<String, dynamic>> loadedLists = [];
    for (String listName in listNames) {
      List<String> movieTitles = prefs.getStringList(listName) ?? [];
      loadedLists.add({
        'name': listName,
        'movies': movieTitles,
      });
    }

    setState(() {
      lists = loadedLists;  // Update lists so the UI gets updated
    });
  }

  // Create a new list
  Future<void> _createList() async {
    final String? listName = await showDialog<String>(
      context: context,
      builder: (context) {
        TextEditingController controller = TextEditingController();
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Enter List Name',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'List Name',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(controller.text),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (lists.any((list) => list['name'] == listName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('List already exists: $listName')),
      );
    } else if (listName != null && listName.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();

      // Add new list to SharedPreferences
      List<String> listNames = prefs.getStringList('listNames') ?? [];
      listNames.add(listName);
      await prefs.setStringList('listNames', listNames);

      // Initialize the list with an empty list of movies
      await prefs.setStringList(listName, []);

      // Reload the lists
      _loadLists();
    }
  }

  // Add a movie to the list using TMDb API
  Future<void> _addMovieToList(String listName, String movieTitle) async {
    final response = await http.get(
      Uri.parse('https://api.themoviedb.org/3/search/movie?api_key=$apiKey&query=$movieTitle'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['results'].isNotEmpty) {
        // Movie is valid, add it to the list
        final movie = data['results'][0];  // Use the first movie in the results
        final movieTitle = movie['title'];
        
        final prefs = await SharedPreferences.getInstance();
        List<String> movieList = prefs.getStringList(listName) ?? [];

        // Add the movie title to the list if not already present
        if (!movieList.contains(movieTitle)) {
          movieList.add(movieTitle);
          await prefs.setStringList(listName, movieList);
          _loadLists(); // Reload lists after modification
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$movieTitle added to $listName')),
          );
        } else {
          // Movie already in list
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$movieTitle is already in $listName')),
          );
        }
      } else {
        // Movie not found in TMDb database
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Movie not found: $movieTitle')),
        );
      }
    } else {
      // Error with TMDb API request
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking movie: $movieTitle')),
      );
    }
  }

  // Remove a movie from the list
  Future<void> _removeMovieFromList(String listName, String movieTitle) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> movieList = prefs.getStringList(listName) ?? [];

    // Remove the movie title from the list
    movieList.remove(movieTitle);

    // Update SharedPreferences with the new list of movies
    await prefs.setStringList(listName, movieList);

    // Reload the list from SharedPreferences and update the UI
    _loadLists();  // Reload lists to ensure UI is updated

    // Show a snack bar with the confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$movieTitle removed from $listName')),
    );

    Navigator.of(context).pop();  // Close the dialog
  }

  // Delete the entire list from SharedPreferences
  Future<void> _deleteList(String listName) async {
  final prefs = await SharedPreferences.getInstance();

  // Remove the list and its associated movies from SharedPreferences
  List<String> listNames = prefs.getStringList('listNames') ?? [];
  listNames.remove(listName);

  // Update the list names in SharedPreferences
  await prefs.setStringList('listNames', listNames);

  // Remove the list's movies data as well
  await prefs.remove(listName);

  // Log to ensure everything is deleted
  logger.info('Deleted list: $listName');
  logger.info('Remaining list names: ${listNames.join(', ')}');

  // Reload the lists to reflect the updated data
  _loadLists();
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Movie Lists'),
        backgroundColor: Colors.deepPurpleAccent,  // Primary color
      ),
      body: lists.isEmpty
          ? const Center(child: Text('No lists available. Create one!'))
          : LayoutBuilder(
              builder: (context, constraints) {
                // Determine if it's a large screen for side-by-side view
                final isLargeScreen = constraints.maxWidth > 800;
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Display lists in a GridView or ListView based on screen size
                      Expanded(
                        child: isLargeScreen
                            ? GridView.builder(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 8.0,  // Reduced space between cards
                                  mainAxisSpacing: 8.0,   // Reduced space between cards
                                ),
                                itemCount: lists.length,
                                itemBuilder: (context, index) {
                                  return _buildListCard(lists[index]);
                                },
                              )
                            : ListView.builder(
                                itemCount: lists.length,
                                itemBuilder: (context, index) {
                                  return _buildListCard(lists[index]);
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createList,
        backgroundColor: Colors.deepPurpleAccent,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Method to build list cards for each list
  Widget _buildListCard(Map<String, dynamic> list) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: () {
          _showListDetails(context, list);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                list['name'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${list['movies'].length} movie(s)',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.bottomRight,
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    // Confirm before deleting the list
                    bool? confirmDelete = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete List'),
                        content: Text('Are you sure you want to delete the list: ${list['name']}?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              _deleteList(list['name']);
                              Navigator.of(context).pop(true);
                            },
                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Dialog to manage movies in the list
  void _showListDetails(BuildContext context, Map<String, dynamic> list) {
    final TextEditingController movieController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          titlePadding: EdgeInsets.zero, // Remove default title padding
          contentPadding: EdgeInsets.all(16), // Add padding for the content
          content: Stack(
            children: [
              // The content of the dialog
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title of the dialog
                  Text(
                    'Manage Movies in ${list['name']}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 48), // More space for the delete icon
                  TextField(
                    controller: movieController,
                    decoration: const InputDecoration(
                      hintText: 'Enter Movie Title',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _addMovieToList(list['name'], movieController.text);
                      movieController.clear();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                    ),
                    child: const Text('Add Movie'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Movies in this list:',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  ...list['movies'].map<Widget>((movie) {
                    return ListTile(
                      title: Text(movie),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () {
                          _removeMovieFromList(list['name'], movie);
                        },
                      ),
                    );
                  }).toList(),
                ],
              ),
              // Positioned Delete Icon at the top-right corner
              Positioned(
                right: 8,
                top: 16, // Increased distance from the top to avoid overlap with title
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    bool? confirmDelete = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete List'),
                        content: Text('Are you sure you want to delete the list: ${list['name']}?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              _deleteList(list['name']);  // Delete the list
                              Navigator.of(context).pop(true);  // Close the confirmation dialog
                              Navigator.of(context).pop();    // Close the main dialog
                            },
                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}