import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'movie.dart'; // Import the MovieScreen class

class ListDetailsPage extends StatefulWidget {
  final String listName;
  final List<String> movies;

  const ListDetailsPage({
    Key? key,
    required this.listName,
    required this.movies,
  }) : super(key: key);

  @override
  _ListDetailsPageState createState() => _ListDetailsPageState();
}

class _ListDetailsPageState extends State<ListDetailsPage> {
  late List<Map<String, dynamic>> movieDetails;
  final String apiKey = 'c6d13ac5863347aa42a5a90abbbd5fec';

  @override
  void initState() {
    super.initState();
    movieDetails = [];
    _loadMovieDetails();
  }

  Future<void> _loadMovieDetails() async {
    for (var title in widget.movies) {
      var details = await _fetchMovieDetails(title);
      if (details.isNotEmpty) {
        setState(() {
          movieDetails.add(details);
        });
      }
    }
  }

  Future<Map<String, dynamic>> _fetchMovieDetails(String movieTitle) async {
    final response = await http.get(
      Uri.parse(
          'https://api.themoviedb.org/3/search/movie?api_key=$apiKey&query=$movieTitle'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['results'].isNotEmpty) {
        final movie = data['results'][0]; // Get the first result
        return {
          'title': movie['title'],
          'poster_path': movie['poster_path'],
          'release_date': movie['release_date'],
          'overview': movie['overview'],
        };
      }
    }
    return {}; // Return empty data if no movie is found or API fails
  }

  Future<void> _addSelectedMovie(String movieTitle) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> movieJsonList = prefs.getStringList(widget.listName) ?? [];

    if (!movieJsonList.contains(movieTitle)) {
      movieJsonList.add(movieTitle);
      await prefs.setStringList(widget.listName, movieJsonList);

      // Fetch movie details
      var details = await _fetchMovieDetails(movieTitle);
      if (details.isNotEmpty) {
        setState(() {
          movieDetails.add(details);
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$movieTitle added to ${widget.listName}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$movieTitle is already in ${widget.listName}')),
      );
    }
  }

  Future<void> _removeMovie(String movieTitle) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> updatedMovies = List.from(widget.movies);
    updatedMovies.remove(movieTitle);

    await prefs.setStringList(widget.listName, updatedMovies);

    setState(() {
      movieDetails.removeWhere((movie) => movie['title'] == movieTitle);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$movieTitle removed from ${widget.listName}')),
    );
  }

  Future<void> _addMovieToListWithSearch() async {
    TextEditingController searchController = TextEditingController();
    List<dynamic> searchResults = [];
    bool isSearching = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> _searchMovies(String query) async {
              if (query.isEmpty) {
                setState(() {
                  searchResults = [];
                });
                return;
              }

              setState(() {
                isSearching = true;
              });

              final response = await http.get(
                Uri.parse(
                    'https://api.themoviedb.org/3/search/movie?api_key=$apiKey&query=$query'),
              );

              if (response.statusCode == 200) {
                final data = json.decode(response.body);
                setState(() {
                  searchResults = data['results'];
                  isSearching = false;
                });
              } else {
                setState(() {
                  searchResults = [];
                  isSearching = false;
                });
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Search and Add Movie',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: searchController,
                      onChanged: (query) => _searchMovies(query),
                      decoration: const InputDecoration(
                        hintText: 'Enter movie title',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (isSearching)
                      const CircularProgressIndicator()
                    else if (searchResults.isNotEmpty)
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final movie = searchResults[index];
                            return ListTile(
                              leading: movie['poster_path'] != null
                                  ? Image.network(
                                      'https://image.tmdb.org/t/p/w200${movie['poster_path']}',
                                      width: 40,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(Icons.image, size: 40),
                              title: Text(movie['title'] ?? 'Unknown'),
                              subtitle: Text(
                                movie['release_date'] != null &&
                                        movie['release_date'].isNotEmpty
                                    ? movie['release_date'].substring(0, 4)
                                    : 'Unknown',
                              ),
                              onTap: () {
                                _addSelectedMovie(movie['title']);
                              },
                            );
                          },
                        ),
                      )
                    else
                      const Text('No results found'),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.listName),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _addMovieToListWithSearch,
              child: const Text('Add Movie'),
            ),
            const SizedBox(height: 16),
            movieDetails.isEmpty
                ? const Center(child: Text('No movies in this list.'))
                : Expanded(
                    child: ListView.builder(
                      itemCount: movieDetails.length,
                      itemBuilder: (context, index) {
                        final movie = movieDetails[index];
                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          child: ListTile(
                            leading: movie['poster_path'] != null
                                ? Image.network(
                                    'https://image.tmdb.org/t/p/w200${movie['poster_path']}',
                                    width: 40,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.image, size: 40),
                            title: Text(movie['title']),
                            subtitle: Text(
                              movie['release_date'] != null &&
                                      movie['release_date'].isNotEmpty
                                  ? movie['release_date'].substring(0, 4)
                                  : 'Unknown',
                            ),
                            onTap: () {
                              // Navigate to MovieScreen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MovieScreen(
                                    movieDetails: movie,
                                  ),
                                ),
                              );
                            },
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _removeMovie(movie['title']);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
