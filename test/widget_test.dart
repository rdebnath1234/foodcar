import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:foodcar/main.dart';

void main() {
  testWidgets('MyApp shows a loading indicator on startup',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
