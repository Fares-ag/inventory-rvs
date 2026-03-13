// Widget tests. Full app test is skipped in test VM (Firebase not available).
// Run unit tests for all flows: models, utils, and logic.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:inventory_system/theme/app_theme.dart';

void main() {
  testWidgets('Theme builds MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: Text('Inventory')),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Inventory'), findsOneWidget);
  });
}
