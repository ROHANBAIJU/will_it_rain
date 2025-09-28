import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nasa_space_app/main.dart';

void main() {
  testWidgets('App renders basic UI without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AppRoot(), // 👈 Correct root widget class
      ),
    );

    await tester.pumpAndSettle();

    // Sanity check: forecast button exists
    expect(find.widgetWithText(ElevatedButton, 'Get Forecast Insights'), findsOneWidget);

    // No exceptions during render
    expect(tester.takeException(), isNull);
  });
}
