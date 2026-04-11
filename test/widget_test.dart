import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wordprogressor/app/app.dart';
import 'package:wordprogressor/core/database/app_database.dart';

// Run with: flutter test
void main() {
  group('WordProgressorApp', () {
    testWidgets('renders without crashing', (tester) async {
      // Create an in-memory database for tests
      final db = AppDatabase();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
          ],
          child: const WordProgressorApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Bottom nav should be visible
      expect(find.text('Projekte'), findsOneWidget);
      expect(find.text('Deadlines'), findsOneWidget);
      expect(find.text('Einstellungen'), findsOneWidget);

      await db.close();
    });

    testWidgets('shows empty state when no projects', (tester) async {
      final db = AppDatabase();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: const WordProgressorApp(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Noch keine Projekte'), findsOneWidget);

      await db.close();
    });
  });
}
