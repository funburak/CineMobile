import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MovieDetailsPage extends StatefulWidget {
  const MovieDetailsPage({super.key});

  @override
  _MovieDetailsPageState createState() => _MovieDetailsPageState();
}

class _MovieDetailsPageState extends State<MovieDetailsPage> {
  final TextEditingController _searchController = TextEditingController();
  bool isLoading = false;
  List<dynamic> searchResults = [];
  String errorMessage = '';
  Map<String, dynamic>? movieDetails;
  String apiKey = 'YOUR_API_KEY';  // Your TMDb API key

  // Search for movies based on the query entered by the user
  Future<void> _searchMovies(String query) async {
    if (query.isEmpty) {
      _loadTopRatedMovies();  // Load the popular movies when query is empty
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('https://api.themoviedb.org/3/search/movie?api_key=$apiKey&query=$query'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'].isNotEmpty) {
          setState(() {
            searchResults = data['results'];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = 'No movies found for "$query".';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Failed to load data. HTTP Status: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred while fetching data: $e';
        isLoading = false;
      });
    }
  }

  // Fetch the 500 top-rated movies
  Future<void> _loadTopRatedMovies() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    // List to store all the fetched top-rated movies
    List<dynamic> allMovies = [];

    try {
      // The total number of pages to fetch (500 movies, 20 per page, so 25 pages)
      int totalPages = 5; // 25 pages * 20 results per page = 500 movies

      // Loop through the pages to get 500 movies
      for (int page = 1; page <= totalPages; page++) {
        final response = await http.get(
          Uri.parse(
            'https://api.themoviedb.org/3/movie/top_rated?api_key=$apiKey&page=$page',
          ),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['results'].isNotEmpty) {
            allMovies.addAll(data['results']);  // Add results from this page to the list
          }
        } else {
          setState(() {
            errorMessage = 'Failed to load top-rated movies';
            isLoading = false;
          });
          return;
        }
      }

      // After collecting all movies, update the state with the results
      setState(() {
        searchResults = allMovies;  // Store the full list of top-rated movies
        isLoading = false;
      });

    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred while fetching top-rated movies: $e';
        isLoading = false;
      });
    }
  }



  // Fetch movie details using the selected movie ID
  Future<void> _fetchMovieDetails(int movieId) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
      movieDetails = null; // Clear previous movie details
      _searchController.clear(); // Clear the search bar
      searchResults = []; // Clear search results
    });

    try {
      final response = await http.get(
        Uri.parse('https://api.themoviedb.org/3/movie/$movieId?api_key=$apiKey'),
      );

      if (response.statusCode == 200) {
        setState(() {
          movieDetails = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load movie details';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred while fetching movie details';
        isLoading = false;
      });
    }
  }

  // Add movie to a selected list
  Future<void> _addMovieToList(String listName, String movieTitle) async {
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

  // Show the list of available lists to the user to add the movie to
  Future<void> _showAddToListDialog(String movieTitle) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> listNames = prefs.getStringList('listNames') ?? [];

    if (listNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No lists available. Create a list first.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select a List'),
          content: SingleChildScrollView(
            child: Column(
              children: listNames.map((listName) {
                return ListTile(
                  title: Text(listName),
                  onTap: () {
                    _addMovieToList(listName, movieTitle);
                    Navigator.pop(context); // Close the dialog
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadTopRatedMovies();  // Load popular movies when the page is first opened
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Search for Movies'),
      backgroundColor: Colors.deepPurpleAccent, // Primary color
    ),
    body: LayoutBuilder(
      builder: (context, constraints) {
        bool isLargeScreen = constraints.maxWidth > 800;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Left side: Search Bar and Results
              Flexible(
                flex: isLargeScreen ? 2 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Search for a movie',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                        fillColor: Colors.white,
                        filled: true,
                      ),
                      onChanged: (query) {
                        if (query.isNotEmpty) {
                          _searchMovies(query);
                        } else {
                          setState(() {
                            searchResults = [];
                            _loadTopRatedMovies();  // Load top-rated movies again when query is empty
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Show loading, error, or search results
                    if (isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (errorMessage.isNotEmpty)
                      Center(child: Text(errorMessage, style: const TextStyle(color: Colors.red)))
                    else if (searchResults.isEmpty)
                      const Center(child: Text('No results found. Try searching again.'))
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true, // Ensures that the ListView is wrapped in a scrollable container
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            var movie = searchResults[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              elevation: 4,
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(8),
                                title: Text(movie['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(movie['release_date']),
                                onTap: () {
                                  _fetchMovieDetails(movie['id']); // Get movie details on tap
                                  _loadTopRatedMovies();
                                },
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),

              // Right side: Movie Details
              if (isLargeScreen) const SizedBox(width: 16), // Add some space between the two sections
              Flexible(
                flex: isLargeScreen ? 3 : 1,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (movieDetails != null)
                        Card(
                          elevation: 4,
                          margin: const EdgeInsets.all(8),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  movieDetails!['title'],
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Image.network(
                                  'https://image.tmdb.org/t/p/w500${movieDetails!['poster_path']}', // TMDb poster image URL
                                  height: 300,
                                  fit: BoxFit.cover,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Release Date: ${movieDetails!['release_date']}',
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  movieDetails!['overview'] ?? 'No description available.',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    // Show available lists when user wants to add the movie
                                    _showAddToListDialog(movieDetails!['title']);
                                  },
                                  child: const Text('Add to List'),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

}
