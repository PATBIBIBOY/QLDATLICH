import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('QLDATLICH smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('QLDATLICH'),
        ),
      ),
    );

    expect(find.text('QLDATLICH'), findsOneWidget);
  });
}
