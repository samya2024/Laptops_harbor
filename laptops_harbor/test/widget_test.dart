import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laptops_harbor/main.dart';

void main() {
  testWidgets('laptops_harbor app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
