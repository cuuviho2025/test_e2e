import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_e2e_demo/main.dart';

void main() {
  testWidgets('submits email and increments counter', (tester) async {
    await tester.pumpWidget(const DemoApp());

    await tester.enterText(
      find.byKey(const Key('emailField')),
      'tester@example.com',
    );
    await tester.tap(find.byKey(const Key('submitButton')));
    await tester.pump();

    expect(find.text('Welcome, tester@example.com'), findsOneWidget);

    await tester.tap(find.byKey(const Key('incrementButton')));
    await tester.pump();

    expect(find.text('Counter: 1'), findsOneWidget);
  });
}
