// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:untitled3/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FitCheckApp());

    // Verify that the app title is displayed
    expect(find.text('FitCheck'), findsOneWidget);
  });

  testWidgets('Intro screen shows and navigates', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FitCheckApp());

    // Wait for initial frame
    await tester.pump();

    // Verify that IntroScreen shows the app name
    expect(find.text('FitCheck'), findsOneWidget);
    expect(find.text('Your Smart Wardrobe Assistant'), findsOneWidget);

    // Wait for navigation (2 seconds delay in IntroScreen)
    await tester.pump(const Duration(seconds: 3));

    // Should have navigated to LoginScreen
    expect(find.text('LOGIN'), findsOneWidget);
  });
}