# Codex Notes

This is a Flutter sample project configured to verify Patrol E2E testing.

## Project State

- Flutter app: `lib/main.dart`
- Widget smoke test: `test/widget_test.dart`
- Patrol E2E test: `patrol_test/app_test.dart`
- Human-facing guide: `README.md`
- Vietnamese Patrol manual guideline: `docs/patrol-e2e-guideline-vi.md`
- Patrol config lives in `pubspec.yaml` under the `patrol:` block.

## Verified Commands

These commands were run successfully:

```bash
flutter analyze
flutter test
~/.pub-cache/bin/patrol test -d chrome --web-headless=true --target patrol_test/app_test.dart
~/.pub-cache/bin/patrol test -d chrome --web-headless=false --target patrol_test/app_test.dart
```

Patrol web result:

```text
Total: 1
Successful: 1
Failed: 0
Skipped: 0
```

## How To Run Patrol

Use the full path unless `~/.pub-cache/bin` is already in `PATH`:

```bash
~/.pub-cache/bin/patrol test -d chrome --web-headless=true --target patrol_test/app_test.dart
```

To run with a visible Chrome browser:

```bash
~/.pub-cache/bin/patrol test -d chrome --web-headless=false --target patrol_test/app_test.dart
```

If launched from a Codex/tool session, Playwright may still run non-headless and
pass while the Chrome window is not attached to the user's visible desktop
session.

## Environment Notes

- Chrome/web and Linux desktop devices were available.
- Android SDK exists, but no Android emulator/device was connected during the
  verified runs.
- iOS was not tested because this environment is Ubuntu.
- `TextInputType.emailAddress` caused a Flutter web engine
  `InvalidStateError` during the first Patrol web run, so the demo uses
  `TextInputType.text` for stable web E2E verification.

## Generated Files

Patrol/Playwright may generate these files/directories:

- `test_bundle.dart`
- `playwright-report/`
- `test-results/`

They are ignored in `.gitignore`.
