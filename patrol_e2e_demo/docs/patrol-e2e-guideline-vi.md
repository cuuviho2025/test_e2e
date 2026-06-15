# Manual Guideline: Dùng Patrol Để Test E2E Cho Flutter

Tài liệu này ghi lại cách setup, chạy, viết test và apply Patrol vào một dự án
Flutter để test E2E. Nội dung dựa trên project mẫu đã chạy pass trong repo này.

## 1. Patrol Là Gì?

Patrol là framework test UI E2E cho Flutter. Nó chạy được các flow người dùng
thật như nhập text, tap button, verify UI, đồng thời có thể điều khiển một số
phần native trên Android/iOS như permission dialog, notification, app lifecycle.

So với `flutter_test` hoặc `integration_test` thuần:

- `flutter_test`: nhanh, phù hợp unit/widget test trong Flutter widget tree.
- `integration_test`: chạy app tích hợp hơn, nhưng hạn chế khi gặp native UI.
- `patrol`: dùng cho E2E UI flow, có finder ngắn gọn và native automation.

## 2. Khi Nào Nên Dùng Patrol?

Dùng Patrol khi cần test các flow giống người dùng thật:

- Login, submit form, navigation nhiều màn hình.
- Verify text, trạng thái button, snackbar, dialog.
- Kiểm tra flow critical trước release.
- Test permission dialog, notification, WebView, native settings trên mobile.
- Chạy smoke test trên CI bằng Chrome/web hoặc emulator.

Không nên thay toàn bộ test bằng Patrol. Nên giữ mô hình:

- Unit test cho business logic.
- Widget test cho component nhỏ.
- Patrol E2E cho flow quan trọng và rủi ro cao.

## 3. Cấu Trúc Project Mẫu

Các file chính trong project này:

```text
lib/main.dart
test/widget_test.dart
patrol_test/app_test.dart
pubspec.yaml
README.md
AGENTS.md
docs/patrol-e2e-guideline-vi.md
```

Ý nghĩa:

- `lib/main.dart`: app mẫu để test.
- `test/widget_test.dart`: widget smoke test bằng Flutter test.
- `patrol_test/app_test.dart`: E2E test bằng Patrol.
- `pubspec.yaml`: khai báo dependency và block `patrol:`.
- `AGENTS.md`: ghi chú cho Codex phiên sau.
- `README.md`: hướng dẫn ngắn cho project.
- `docs/patrol-e2e-guideline-vi.md`: manual tiếng Việt này.

## 4. Cài Patrol CLI

Cài hoặc update Patrol CLI:

```bash
dart pub global activate patrol_cli
```

Kiểm tra CLI:

```bash
~/.pub-cache/bin/patrol --version
~/.pub-cache/bin/patrol doctor
```

Nếu muốn gọi `patrol` trực tiếp, thêm vào shell config:

```bash
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

Sau đó có thể chạy:

```bash
patrol doctor
```

Trong project mẫu này, CLI đã được gọi bằng full path:

```bash
~/.pub-cache/bin/patrol
```

## 5. Thêm Patrol Vào Flutter Project

Trong root của Flutter project:

```bash
flutter pub add patrol --dev
```

Sau đó thêm block `patrol:` vào `pubspec.yaml`.

Ví dụ Android/web tối thiểu:

```yaml
patrol:
  app_name: Your App Name
  android:
    package_name: com.example.your_app
```

Nếu có iOS/macOS:

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

Lấy `package_name` Android từ `android/app/build.gradle` hoặc
`android/app/build.gradle.kts`. Lấy `bundle_id` iOS từ Xcode project hoặc
`ios/Runner.xcodeproj`.

## 6. Viết Test Patrol Đầu Tiên

Tạo thư mục:

```bash
mkdir -p patrol_test
```

Tạo file:

```text
patrol_test/app_test.dart
```

Ví dụ test:

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

Các điểm quan trọng:

- `patrolTest(...)` là wrapper test của Patrol.
- `$` là `PatrolIntegrationTester`.
- `$(#emailField)` tìm widget theo `Key('emailField')`.
- `$('Some text')` tìm widget theo text.
- `enterText`, `tap`, `scrollTo`, `waitUntilVisible` là các action hay dùng.
- Dùng `expect(..., findsOneWidget)` từ `flutter_test`.

Trong app, cần đặt key cho widget quan trọng:

```dart
TextField(
  key: const Key('emailField'),
)

FilledButton(
  key: const Key('submitButton'),
  onPressed: submit,
  child: const Text('Submit'),
)
```

## 7. Chạy Test Trên Web

Chạy headless, phù hợp CI hoặc terminal:

```bash
~/.pub-cache/bin/patrol test -d chrome --web-headless=true --target patrol_test/app_test.dart
```

Chạy Chrome visible để xem flow:

```bash
~/.pub-cache/bin/patrol test -d chrome --web-headless=false --target patrol_test/app_test.dart
```

Nếu đã thêm `~/.pub-cache/bin` vào `PATH`:

```bash
patrol test -d chrome --web-headless=true --target patrol_test/app_test.dart
patrol test -d chrome --web-headless=false --target patrol_test/app_test.dart
```

Lưu ý khi chạy từ Codex/tool session: command `--web-headless=false` vẫn chạy
non-headless, nhưng cửa sổ Chrome có thể không attach vào desktop session mà bạn
đang nhìn thấy. Khi đó vẫn dựa vào output của Patrol để xác nhận pass/fail.

## 8. Kết Quả Đã Verify Trong Project Này

Các command đã pass:

```bash
flutter analyze
flutter test
~/.pub-cache/bin/patrol test -d chrome --web-headless=true --target patrol_test/app_test.dart
~/.pub-cache/bin/patrol test -d chrome --web-headless=false --target patrol_test/app_test.dart
```

Kết quả Patrol:

```text
Total: 1
Successful: 1
Failed: 0
Skipped: 0
```

Flow đã test:

```text
enterText emailField
tap submitButton
verify Welcome, tester@example.com
tap incrementButton
tap incrementButton
verify Counter: 2
```

## 9. Chạy Test Trên Android

Kiểm tra device:

```bash
flutter devices
```

Nếu có emulator/device, chạy:

```bash
~/.pub-cache/bin/patrol test -d <device_id> --target patrol_test/app_test.dart
```

Ví dụ:

```bash
~/.pub-cache/bin/patrol test -d emulator-5554 --target patrol_test/app_test.dart
```

Nếu Android licenses chưa accepted:

```bash
flutter doctor --android-licenses
```

Trong môi trường đã verify project này, Android SDK có tồn tại nhưng không có
Android emulator/device đang connected, nên mới verify trên Chrome/web.

## 10. Pattern Viết Test Nên Dùng

Nên đặt tên test theo user flow:

```dart
patrolTest('user can sign in with valid credentials', ($) async {
  ...
});
```

Nên ưu tiên key ổn định:

```dart
await $(#loginEmailField).enterText('user@example.com');
await $(#loginPasswordField).enterText('password123');
await $(#loginButton).tap();
```

Nên verify kết quả user nhìn thấy:

```dart
expect($('Dashboard'), findsOneWidget);
expect($('Welcome back'), findsOneWidget);
```

Nên tách helper nếu flow lặp lại:

```dart
Future<void> login(PatrolIntegrationTester $, String email, String password) async {
  await $(#emailField).enterText(email);
  await $(#passwordField).enterText(password);
  await $(#loginButton).tap();
}
```

Không nên phụ thuộc vào animation timing cố định nếu có thể tránh. Ưu tiên:

```dart
await $('Dashboard').waitUntilVisible();
```

thay vì sleep cứng.

## 11. Native Automation Trên Mobile

Patrol mạnh hơn `integration_test` thuần ở phần native automation. Ví dụ các
case phù hợp trên Android/iOS:

- Runtime permission dialog.
- Notification shade.
- App background/foreground.
- Native WebView/login provider.
- Native settings hoặc system UI.

Ví dụ ý tưởng:

```dart
patrolTest('handles location permission', ($) async {
  await $.pumpWidgetAndSettle(const YourApp());

  await $(#requestLocationButton).tap();

  if (await $.platform.mobile.isPermissionDialogVisible()) {
    await $.platform.mobile.grantPermissionWhenInUse();
  }

  expect($('Location granted'), findsOneWidget);
});
```

Các API native có thể thay đổi theo version Patrol, nên khi viết case native
cần kiểm tra docs/API hiện tại của package đang dùng.

## 12. Debug Lỗi Thường Gặp

### `patrol: command not found`

Dùng full path:

```bash
~/.pub-cache/bin/patrol doctor
```

Hoặc thêm PATH:

```bash
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

### Không thấy Android device

Chạy:

```bash
flutter devices
flutter doctor -v
```

Cần bật emulator hoặc cắm device thật, bật USB debugging.

### Test không tìm thấy widget

Kiểm tra:

- Widget có `Key(...)` đúng chưa.
- Text có đúng chính tả không.
- Widget đã visible chưa.
- Có cần `waitUntilVisible()` không.
- Có navigation/animation chưa settle không.

### Flutter web lỗi với input email

Trong project này, lần chạy đầu với `TextInputType.emailAddress` trên web gây
lỗi Flutter web engine:

```text
InvalidStateError: Failed to execute 'setSelectionRange' on 'HTMLInputElement'
```

Demo đã đổi sang:

```dart
keyboardType: TextInputType.text
```

để smoke test web ổn định.

### Playwright report và file generated

Patrol web có thể sinh ra:

```text
test_bundle.dart
playwright-report/
test-results/
```

Trong project này các file đó đã được ignore trong `.gitignore`.

## 13. Checklist Apply Vào Dự Án Thật

1. Chạy `flutter analyze` để đảm bảo project sạch.
2. Cài/update Patrol CLI.
3. Thêm `patrol` vào `dev_dependencies`.
4. Thêm block `patrol:` vào `pubspec.yaml`.
5. Đặt `Key` cho các UI element quan trọng.
6. Tạo `patrol_test/app_test.dart`.
7. Viết smoke E2E flow ngắn nhất trước.
8. Chạy trên web bằng Chrome headless.
9. Nếu dự án mobile, chạy thêm Android/iOS device thật hoặc emulator.
10. Thêm test vào CI sau khi local pass ổn định.
11. Ignore generated files của Patrol/Playwright.
12. Chỉ mở rộng E2E cho các flow quan trọng, không biến E2E thành test mọi chi tiết nhỏ.

## 14. Command Nhanh

```bash
# Check Flutter project
flutter analyze
flutter test

# Check Patrol
~/.pub-cache/bin/patrol doctor

# Run Patrol web headless
~/.pub-cache/bin/patrol test -d chrome --web-headless=true --target patrol_test/app_test.dart

# Run Patrol web visible
~/.pub-cache/bin/patrol test -d chrome --web-headless=false --target patrol_test/app_test.dart

# List devices
flutter devices

# Run Patrol on a specific device
~/.pub-cache/bin/patrol test -d <device_id> --target patrol_test/app_test.dart
```
