import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:patrol_e2e_demo/main.dart';

void main() {
  Future<void> pumpDemo(PatrolIntegrationTester $) async {
    await $.pumpWidgetAndSettle(const DemoApp());
  }

  patrolTest('submits an email and increments the counter', ($) async {
    await pumpDemo($);

    await $(#emailField).enterText('tester@example.com');
    await $(#submitButton).tap();

    expect($('Welcome, tester@example.com'), findsOneWidget);

    await $(#incrementButton).tap();
    await $(#incrementButton).tap();

    expect($('Counter: 2'), findsOneWidget);
  });

  patrolTest('keeps the empty submit state stable', ($) async {
    await pumpDemo($);

    expect($(#welcomeMessage).text, 'No email submitted');

    await $(#submitButton).tap();

    expect($(#welcomeMessage).text, 'No email submitted');
    expect($(#counterText).text, 'Counter: 0');
  });

  patrolTest('replaces a submitted email with the latest input', ($) async {
    await pumpDemo($);

    await $(#emailField).enterText('first@example.com');
    await $(#submitButton).tap();

    expect($(#welcomeMessage).text, 'Welcome, first@example.com');

    await $(#emailField).enterText('second@example.com');
    await $(#submitButton).tap();

    expect($(#welcomeMessage).text, 'Welcome, second@example.com');
  });

  patrolTest('handles a repeated counter tap sequence', ($) async {
    await pumpDemo($);

    for (var i = 0; i < 20; i += 1) {
      await $(#incrementButton).tap();
    }

    expect($(#counterText).text, 'Counter: 20');
  });
}
