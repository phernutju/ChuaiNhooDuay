// Widget tests for pure UI components that don't require Firebase init.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:we_are_ready/features/widgets/app_widgets.dart';

void main() {
  testWidgets('PrimaryButton renders label and fires onPressed',
      (WidgetTester tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrimaryButton(
            label: 'Send verification code',
            onPressed: () => tapped++,
          ),
        ),
      ),
    );
    expect(find.text('Send verification code'), findsOneWidget);
    await tester.tap(find.byType(PrimaryButton));
    await tester.pump();
    expect(tapped, 1);
  });

  testWidgets('PrimaryButton disabled when onPressed is null',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PrimaryButton(label: 'Verify', onPressed: null),
        ),
      ),
    );
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });
}
