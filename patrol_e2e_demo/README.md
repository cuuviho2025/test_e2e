# Patrol E2E Demo

Flutter sample project configured to run E2E UI tests with Patrol.

Vietnamese manual guideline:

```text
docs/patrol-e2e-guideline-vi.md
```

## What Was Verified

These commands passed in this project:

```bash
flutter analyze
flutter test
~/.pub-cache/bin/patrol test -d chrome --web-headless=true --target patrol_test/app_test.dart
~/.pub-cache/bin/patrol test -d chrome --web-headless=false --target patrol_test/app_test.dart
~/.pub-cache/bin/patrol test -d emulator-5554 --target patrol_test/app_test.dart
```

Patrol result:

```text
Total: 4
Successful: 4
Failed: 0
Skipped: 0
```

Codex ran the visible-browser command after the headless run. Patrol reported
the same successful E2E flow:

```text
enterText emailField -> OK
tap submitButton -> OK
tap incrementButton -> OK
tap incrementButton -> OK
verify Counter: 2 -> OK
empty submit keeps No email submitted -> OK
replace submitted email -> OK
20 repeated counter taps -> OK
```

Android was verified on `Medium_Phone_API_36.1` / `emulator-5554` after adding
the required Patrol native Android test stub:

```text
android/app/src/androidTest/java/com/example/patrol_e2e_demo/MainActivityTest.java
```

Without this stub, Android instrumentation can build and exit successfully while
reporting `Total: 0`, because no JUnit test class is present to call into the
bundled Dart Patrol tests.

## Installed Pieces

- `patrol` dev dependency in `pubspec.yaml`
- `patrol_cli` global CLI, currently callable at `~/.pub-cache/bin/patrol`
- `patrol:` config in `pubspec.yaml`
- E2E test entrypoint at `patrol_test/app_test.dart`
- Android Patrol JUnit bridge at
  `android/app/src/androidTest/java/com/example/patrol_e2e_demo/MainActivityTest.java`

## Run The Demo Test

Run headless in CI or normal terminal verification:

```bash
cd /home/alex/Desktop/dev/codex/test_e2e/patrol_e2e_demo
~/.pub-cache/bin/patrol test -d chrome --web-headless=true --target patrol_test/app_test.dart
```

Run with a visible Chrome browser:

```bash
cd /home/alex/Desktop/dev/codex/test_e2e/patrol_e2e_demo
~/.pub-cache/bin/patrol test -d chrome --web-headless=false --target patrol_test/app_test.dart
```

If the command is launched from an automated Codex/tool session, Playwright can
still run in non-headless mode and pass while the browser window is not attached
to your visible desktop session.

If you add `~/.pub-cache/bin` to your shell `PATH`, this becomes:

```bash
patrol test -d chrome --web-headless=true --target patrol_test/app_test.dart
```

## Apply Patrol To Another Flutter Project

1. Install or update Patrol CLI:

   ```bash
   dart pub global activate patrol_cli
   ```

2. Add Patrol to the project:

   ```bash
   flutter pub add patrol --dev
   ```

3. Add a `patrol:` block to `pubspec.yaml`:

   ```yaml
   patrol:
     app_name: Your App Name
     android:
       package_name: com.example.your_app
   ```

   For iOS/macOS, also add the bundle ids:

   ```yaml
   patrol:
     app_name: Your App Name
     android:
       package_name: com.example.your_app
     ios:
       bundle_id: com.example.YourApp
     macos:
       bundle_id: com.example.macos.YourApp
   ```

4. Create a test under `patrol_test/`:

   ```dart
   import 'package:flutter_test/flutter_test.dart';
   import 'package:patrol/patrol.dart';
   import 'package:your_app/main.dart';

   void main() {
     patrolTest('main user flow', ($) async {
       await $.pumpWidgetAndSettle(const YourApp());

       await $(#emailField).enterText('tester@example.com');
       await $(#submitButton).tap();

       expect($('Welcome, tester@example.com'), findsOneWidget);
     });
   }
   ```

5. Run on web:

   ```bash
   patrol test -d chrome --web-headless=true --target patrol_test/app_test.dart
   ```

   To watch the E2E flow in Chrome:

   ```bash
   patrol test -d chrome --web-headless=false --target patrol_test/app_test.dart
   ```

6. Run on Android after an emulator/device is connected:

   ```bash
   patrol test -d emulator-5554 --target patrol_test/app_test.dart
   ```

   Replace `emulator-5554` with the device id from:

   ```bash
   flutter devices
   ```

   Android projects also need the Patrol JUnit bridge under
   `android/app/src/androidTest/java/<your/package>/MainActivityTest.java`.
   Copy the pattern from this repo and update the package name and
   `MainActivity` import/package to match the app.

## Android Emulator Performance Notes

Patrol Android runs more slowly than web/widget tests because it builds the app
APK and androidTest APK, installs them through ADB, starts Android
instrumentation, then runs the Dart test through Patrol's native bridge. The
actual Dart flow in this demo takes only a few seconds; most time is build,
install, and instrumentation startup.

Expected rough timings:

- First run on a new PC or cold cache: several minutes, sometimes 10-15 minutes
  on slower machines or after dependency/SDK changes.
- Warm build with emulator already booted and Gradle cache intact: about 9
  seconds for this demo.
- Warm Android Patrol run for the current 4-test suite: about 2m46s.
- Individual Dart UI test cases in the current suite: about 3-21 seconds each.

To keep runs fast on another PC:

- Keep the emulator open between runs.
- Avoid `flutter clean` unless diagnosing a cache problem.
- Keep Gradle daemon/cache enabled.
- Run `flutter pub get` once before Patrol.
- Run `flutter analyze` and `flutter test` before Android E2E to catch cheap
  failures early.
- Use one stable x86_64 emulator image for local E2E.
- Consider limiting debug ABI to the emulator ABI in larger apps if native build
  time dominates.
- Do not rely on deleting emulator apps to make builds fast; it mostly reduces
  background noise, not Gradle/Flutter build time.

## Notes From This Setup

- `flutter test` is still useful for fast widget tests, but Patrol E2E tests
  should be run with `patrol test`.
- Patrol can test normal Flutter UI flows and can also automate native mobile
  surfaces on Android/iOS, such as permission dialogs and notifications.
- On web, avoid `TextInputType.emailAddress` for this smoke test path because
  the current Flutter web engine raised an `InvalidStateError` during browser
  selection handling. This demo uses `TextInputType.text` for stable execution.
- Patrol generates `test_bundle.dart`, `playwright-report/`, and
  `test-results/`; they are ignored in this project.
