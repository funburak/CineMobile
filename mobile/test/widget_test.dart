import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cinemobile/main.dart';
import 'package:cinemobile/providers/list_provider.dart';

void main() {
  testWidgets('Add a new list and verify its presence', (WidgetTester tester) async {
    // Build our app with the ListProvider (for state management)
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => ListProvider(),
        child:  const MyApp(),
      ),
    );

    // Navigate to the ListsPage
    await tester.tap(find.text('My Lists'));
    await tester.pumpAndSettle();

    // Verify that initially no lists are present
    expect(find.text('No lists available'), findsOneWidget);

    // Tap the FloatingActionButton (to add a new list)
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Enter a name for the new list in the dialog and submit it
    await tester.enterText(find.byType(TextField), 'My Favorite Movies');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Verify that the new list name appears in the ListView
    expect(find.text('My Favorite Movies'), findsOneWidget);

    // // Optionally, verify that the correct list is added to the provider's state
    // final listProvider = tester.widget<ChangeNotifierProvider<ListProvider>>(
    //   find.byType(ChangeNotifierProvider<ListProvider>),
    // ).create!();
    // expect(listProvider.lists.contains('My Favorite Movies'), true);
  });
}
