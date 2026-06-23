# Codex Notes

This is a Flutter sample project configured to verify Patrol E2E testing.

## Project State

- Flutter app: `lib/main.dart`
- Widget smoke test: `test/widget_test.dart`
- Patrol E2E test: `patrol_test/app_test.dart`
- Android Patrol JUnit bridge:
  `android/app/src/androidTest/java/com/example/patrol_e2e_demo/MainActivityTest.java`
- Human-facing guide: `README.md`
- Vietnamese Patrol manual guideline: `docs/patrol-e2e-guideline-vi.md`
- Patrol config lives in `pubspec.yaml` under the `patrol:` block.
- Latest committed Patrol update:
  `3cd5d8e Add Android Patrol E2E performance coverage`

## Verified Commands

These commands were run successfully:

```bash
flutter analyze
flutter test
~/.pub-cache/bin/patrol test -d chrome --web-headless=true --target patrol_test/app_test.dart
~/.pub-cache/bin/patrol test -d chrome --web-headless=false --target patrol_test/app_test.dart
~/.pub-cache/bin/patrol test -d emulator-5554 --target patrol_test/app_test.dart
~/.pub-cache/bin/patrol test -d emulator-5554 --target patrol_test/app_test.dart --verbose
```

Current Patrol Android result:

```text
Total: 4
Successful: 4
Failed: 0
Skipped: 0
```

Measured Android performance on `Medium_Phone_API_36.1` / `emulator-5554`:

```text
first run after test changes: build 21.8s, total 2m42s
warm run immediately after: build 8.7s, total 2m46s
individual test durations: about 9s, 4s, 7s, 21s
```

## How To Run Patrol

Use the full path unless `~/.pub-cache/bin` is already in `PATH`:

```bash
~/.pub-cache/bin/patrol test -d chrome --web-headless=true --target patrol_test/app_test.dart
```

Run on Android after an emulator/device is connected:

```bash
flutter devices
~/.pub-cache/bin/patrol test -d emulator-5554 --target patrol_test/app_test.dart
```

To run with a visible Chrome browser:

```bash
~/.pub-cache/bin/patrol test -d chrome --web-headless=false --target patrol_test/app_test.dart
```

If launched from a Codex/tool session, Playwright may still run non-headless and
pass while the Chrome window is not attached to the user's visible desktop
session.

## Environment Notes

- Chrome/web, Linux desktop, and Android emulator devices were available.
- Android was verified on `Medium_Phone_API_36.1` / `emulator-5554`
  (Android 16 / API 36).
- `~/.pub-cache/bin/patrol --version` reported `patrol_cli v4.4.0`.
- `pubspec.yaml` uses `patrol: ^4.6.1`.
- If Android Patrol reports `Total: 0`, check that
  `android/app/src/androidTest/java/com/example/patrol_e2e_demo/MainActivityTest.java`
  exists. Without this JUnit bridge, instrumentation can build successfully but
  not discover Dart Patrol tests.
- Emulator was cleaned for this session: `pm list packages -3` returned empty,
  and launcher activities were only Settings and Files/DocumentsUI.
- Deleting emulator apps is not the main performance optimization; most time is
  Gradle/Flutter build, ADB install, Android instrumentation, orchestrator, and
  Patrol app service startup.
- iOS was not tested because this environment is Ubuntu.
- `TextInputType.emailAddress` caused a Flutter web engine
  `InvalidStateError` during the first Patrol web run, so the demo uses
  `TextInputType.text` for stable web E2E verification.

## Worktree Notes

After commit `3cd5d8e`, these files remained dirty from earlier work and were
not included in the commit:

```text
patrol_e2e_demo/android/app/build.gradle.kts
patrol_e2e_demo/android/gradle.properties
patrol_e2e_demo/android/gradle/wrapper/gradle-wrapper.properties
```

## Generated Files

Patrol/Playwright may generate these files/directories:

- `test_bundle.dart`
- `playwright-report/`
- `test-results/`

They are ignored in `.gitignore`.
