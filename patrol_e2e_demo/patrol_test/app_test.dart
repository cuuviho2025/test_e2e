import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:patrol_e2e_demo/main.dart';

void main() {
  patrolTest('submits an email and increments the counter', ($) async {
    await $.pumpWidgetAndSettle(const DemoApp());

    await $(#emailField).enterText('tester@example.com');
    await $(#submitButton).tap();

    expect($('Welcome, tester@example.com'), findsOneWidget);

    await $(#incrementButton).tap();
    await $(#incrementButton).tap();

    expect($('Counter: 2'), findsOneWidget);
  });
}
