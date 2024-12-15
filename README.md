# CineMobile

CineMobile is a Flutter-based mobile application designed to provide information about movies.

---

## Prerequisites

1. Ensure you have the [Flutter SDK](https://flutter.dev/docs/get-started/install) installed on your system.
2. Verify your Flutter installation:
   ```bash
   flutter --version

## Configure Your API Key

This project uses an external API (e.g., TMDB API) for fetching movie details.

1. Obtain an API key from [TMDB](https://www.themoviedb.org/).
2. Open the files where the API key is set (e.g., `lib/chatbot.dart` or `lib/movie_details.dart`).
3. Replace the placeholder `YOUR_API_KEY` with your actual API key:
   ```dart
   const String apiKey = "YOUR_API_KEY";

## Building The App

To build the project, follow these steps

1. Install dependencies (flutter pub get)
2. Build the APK (flutter build apk)
3. The APK will be at build/app/outputs/flutter-apk/app-release.apk

## Download the release APK

To run the project on your own device download the apk
1. Download the cinemobile.apk

## RAG Part

1. The requirements.txt file contains the necessary versions to run RAG and backend codes written in Python.
2. After completing the installations, simply run the appllm.py file.
