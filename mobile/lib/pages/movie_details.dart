import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'movie.dart'; // Import the new screen

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
  String apiKey = 'c6d13ac5863347aa42a5a90abbbd5fec';

  Future<void> _searchMovies(String query) async {
    if (query.isEmpty) {
      _loadTopRatedMovies();
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://api.themoviedb.org/3/search/movie?api_key=$apiKey&query=$query'),
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
          errorMessage =
              'Failed to load data. HTTP Status: ${response.statusCode}';
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

  Future<void> _loadTopRatedMovies() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://api.themoviedb.org/3/movie/top_rated?api_key=$apiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          searchResults = data['results'];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load top-rated movies';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred while fetching top-rated movies: $e';
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadTopRatedMovies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search for Movies'),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
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
                  _loadTopRatedMovies();
                }
              },
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (errorMessage.isNotEmpty)
              Center(
                  child: Text(errorMessage,
                      style: const TextStyle(color: Colors.red)))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    var movie = searchResults[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 4,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(8),
                        // Add the movie poster here
                        leading: movie['poster_path'] != null
                            ? Image.network(
                                'https://image.tmdb.org/t/p/w200${movie['poster_path']}',
                                width: 35, // Adjust width for consistent sizing
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.image,
                                size: 50), // Placeholder for missing poster
                        title: Text(movie['title'],
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          movie['release_date'] != null &&
                                  movie['release_date'].isNotEmpty
                              ? movie['release_date'].substring(0, 4)
                              : 'Unknown',
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MovieScreen(movieDetails: movie),
                            ),
                          );
                        },
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
