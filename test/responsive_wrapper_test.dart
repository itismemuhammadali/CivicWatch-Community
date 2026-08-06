import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cctv_app/main.dart'; // import the app

void main() {
  testWidgets('Test MyApp builds successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(ConstrainedBox), findsWidgets);
  });
}
