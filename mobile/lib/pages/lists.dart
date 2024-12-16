import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';
import 'list_details_page.dart';

class ListsPage extends StatefulWidget {
  const ListsPage({super.key});

  @override
  _ListsPageState createState() => _ListsPageState();
}

class _ListsPageState extends State<ListsPage> {
  List<Map<String, dynamic>> lists = []; // List of lists and their movies
  bool isLoading = false;
  String apiKey =
      'c6d13ac5863347aa42a5a90abbbd5fec'; // Replace with your TMDb API key
  final Logger logger = Logger('ListsPage');

  @override
  void initState() {
    super.initState();
    _loadLists(); // Load lists from SharedPreferences
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
      lists = loadedLists; // Update lists so the UI gets updated
    });
  }

  // Create a new list
  Future<void> _createList() async {
    final String? listName = await showDialog<String>(
      context: context,
      builder: (context) {
        TextEditingController controller = TextEditingController();
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context).pop(controller.text),
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

      List<String> listNames = prefs.getStringList('listNames') ?? [];
      listNames.add(listName);
      await prefs.setStringList('listNames', listNames);

      await prefs.setStringList(listName, []);

      _loadLists();
    }
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
        backgroundColor: Colors.deepPurpleAccent, // Primary color
      ),
      body: lists.isEmpty
          ? const Center(child: Text('No lists available. Create one!'))
          : LayoutBuilder(
              builder: (context, constraints) {
                final isLargeScreen = constraints.maxWidth > 800;
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Expanded(
                        child: isLargeScreen
                            ? GridView.builder(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 8.0,
                                  mainAxisSpacing: 8.0,
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

  Widget _buildListCard(Map<String, dynamic> list) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: () {
          // Navigate to ListDetailsPage and refresh when returning
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ListDetailsPage(
                listName: list['name'],
                movies: List<String>.from(list['movies']),
              ),
            ),
          ).then((_) {
            // Refresh lists when returning
            _loadLists();
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // List title and movie count
              Column(
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
                ],
              ),
              // Delete button
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  // Show a confirmation dialog before deleting the list
                  await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete List'),
                      content: Text(
                          'Are you sure you want to delete the list: ${list['name']}?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            _deleteList(list['name']); // Delete the list
                            Navigator.of(context).pop(true); // Close the dialog
                          },
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
