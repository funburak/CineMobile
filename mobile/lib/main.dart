import 'package:flutter/material.dart';
import 'package:cinemobile/pages/movie_details.dart';
import 'package:cinemobile/pages/lists.dart';
import 'package:cinemobile/pages/chatbot.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cinemobile',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      home: const HomePage(),  // Directly show the HomePage
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;  // Track the selected page index

  // Handle page selection
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;  // Update the selected index
    });
  }

  @override
  Widget build(BuildContext context) {
    // List of pages (corresponding to BottomNavigationBar)
    final List<Widget> _pages = [
      const MovieDetailsPage(),  // Page 0
      const ListsPage(),         // Page 1
      const ChatbotPage(),       // Page 2
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to Cinemobile'),
      ),
      body: _pages[_selectedIndex],  // Render the selected page based on _selectedIndex
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,  // Highlight the selected icon
        onTap: _onItemTapped,  // Handle taps on the icons
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Movies',  // Label for MovieDetailsPage
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Lists',  // Label for ListsPage
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chatbot',  // Label for ChatbotPage
          ),
        ],
      ),
    );
  }
}
