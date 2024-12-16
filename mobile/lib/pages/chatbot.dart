import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  _ChatbotPageState createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _controller = TextEditingController();
  List<Widget> messages = [];
  bool isLoading = false;

  // TMDB API key (replace with your API key)
  final String tmdbApiKey = 'c6d13ac5863347aa42a5a90abbbd5fec';

  void _sendMessage() async {
    if (_controller.text.isEmpty) return;

    String userMessage = _controller.text;
    setState(() {
      messages.add(
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'You: $userMessage',
              style: TextStyle(
                color: Colors.blue[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
      isLoading = true;
    });

    try {
      // Fetch movie data from your chatbot server
      final response = await http.post(
        Uri.parse('https://cinechatrag.onrender.com/get'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Access-Control-Allow-Origin': '*',
        },
        body: {
          'msg': userMessage,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['movies'] != null) {
          List<Widget> movieWidgets = [];

          for (var movie in data['movies']) {
            String title = movie['title'];

            // Fetch poster URL from TMDB API
            final tmdbResponse = await http.get(
              Uri.parse(
                'https://api.themoviedb.org/3/search/movie?api_key=$tmdbApiKey&query=${Uri.encodeComponent(title)}',
              ),
            );

            String posterUrl = '';
            if (tmdbResponse.statusCode == 200) {
              final tmdbData = json.decode(tmdbResponse.body);
              if (tmdbData['results'] != null && tmdbData['results'].isNotEmpty) {
                posterUrl = 'https://image.tmdb.org/t/p/w500${tmdbData['results'][0]['poster_path']}';
              }
            }

            movieWidgets.add(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  posterUrl.isNotEmpty
                      ? Image.network(
                          posterUrl,
                          height: 200,
                          width: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Text("Image not available");
                          },
                        )
                      : const Text("Poster not available"),
                  const SizedBox(height: 10),
                  Text(
                    "${movie['title']} (Rating: ${movie['rating']})",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Summary: ${movie['summary']}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
          setState(() {
            messages.addAll(movieWidgets);
          });
        } else {
          setState(() {
            messages.add(
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text("Bot: Couldn't find any matching movies."),
                ),
              ),
            );
          });
        }
      } else {
        setState(() {
          messages.add(
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Bot: Server returned status code ${response.statusCode}.',
                ),
              ),
            ),
          );
        });
      }
    } catch (e) {
      setState(() {
        messages.add(
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('Bot: Failed to connect to the server: $e'),
            ),
          ),
        );
      });
    } finally {
      setState(() {
        isLoading = false;
        _controller.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movie Chatbot'),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) => messages[index], // Directly use Widget from the list
              ),
            ),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: CircularProgressIndicator(),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'Ask a question about movies',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
