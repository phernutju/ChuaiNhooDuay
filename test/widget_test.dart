import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:we_are_ready/main.dart';

void main() {
  testWidgets('App renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: WeAreReadyApp()));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
