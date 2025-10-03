import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aeronimbus/main.dart';

void main() {
  testWidgets('App renders basic UI without crashing', (WidgetTester tester) async {
    // Render the real app root
    await tester.pumpWidget(const AeroNimbusRoot());

    await tester.pumpAndSettle();

    // Basic sanity checks: app renders and a MaterialApp is present
    expect(find.byType(MaterialApp), findsOneWidget);

    // No exceptions during render
    expect(tester.takeException(), isNull);
  });
}
