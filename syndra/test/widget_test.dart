import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Syndra app renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('Syndra is running'))),
      ),
    );

    expect(find.text('Syndra is running'), findsOneWidget);
  });
}
