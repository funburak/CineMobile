import 'package:flutter/material.dart';

class ListProvider with ChangeNotifier {
  // A map to store list names and their respective movie titles
  final Map<String, List<String>> _lists = {};

  // Getter to access the lists
  Map<String, List<String>> get lists => _lists;

  // Add a new list
  void addList(String listName) {
    if (!_lists.containsKey(listName)) {
      _lists[listName] = [];
      notifyListeners();
    }
  }

  // Remove a list
  void removeList(String listName) {
    _lists.remove(listName);
    notifyListeners();
  }

  // Add a movie to a list
  void addMovieToList(String listName, String movieTitle) {
    if (_lists.containsKey(listName)) {
      _lists[listName]?.add(movieTitle);
      notifyListeners();
    }
  }

  // Remove a movie from a list
  void removeMovieFromList(String listName, String movieTitle) {
    _lists[listName]?.remove(movieTitle);
    notifyListeners();
  }
}
