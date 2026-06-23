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
android/app/src/androidTest/java/com/example/patrol_e2e_demo/MainActivityTest.java
pubspec.yaml
README.md
AGENTS.md
docs/patrol-e2e-guideline-vi.md
```

Ý nghĩa:

- `lib/main.dart`: app mẫu để test.
- `test/widget_test.dart`: widget smoke test bằng Flutter test.
- `patrol_test/app_test.dart`: E2E test bằng Patrol.
- `android/app/src/androidTest/.../MainActivityTest.java`: bridge JUnit để
  Patrol Android gọi được các test Dart đã bundle.
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

### Setup Android Bắt Buộc

Trong `android/app/build.gradle` hoặc `android/app/build.gradle.kts`, cần dùng
Patrol runner:

```kotlin
defaultConfig {
    testInstrumentationRunner = "pl.leancode.patrol.PatrolJUnitRunner"
    testInstrumentationRunnerArguments["clearPackageData"] = "true"
}

testOptions {
    execution = "ANDROIDX_TEST_ORCHESTRATOR"
}

dependencies {
    androidTestUtil("androidx.test:orchestrator:1.5.1")
}
```

Với Android Patrol, project cũng cần một JUnit bridge ở source set
`androidTest`. Nếu thiếu file này, Gradle vẫn có thể build và command
`patrol test` vẫn exit `0`, nhưng report sẽ là:

```text
Total: 0
Successful: 0
Failed: 0
Skipped: 0
```

Đó không phải là test pass thật. Nó nghĩa là Android instrumentation không có
JUnit test class nào để gọi sang danh sách Dart Patrol tests.

Tạo file theo package app của bạn:

```text
android/app/src/androidTest/java/com/example/your_app/MainActivityTest.java
```

Nội dung mẫu:

```java
package com.example.your_app;

import androidx.test.platform.app.InstrumentationRegistry;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.junit.runners.Parameterized;
import org.junit.runners.Parameterized.Parameters;
import pl.leancode.patrol.PatrolJUnitRunner;

@RunWith(Parameterized.class)
public class MainActivityTest {
    @Parameters(name = "{0}")
    public static Object[] testCases() {
        PatrolJUnitRunner instrumentation =
                (PatrolJUnitRunner) InstrumentationRegistry.getInstrumentation();
        instrumentation.setUp(MainActivity.class);
        instrumentation.waitForPatrolAppService();
        return instrumentation.listDartTests();
    }

    public MainActivityTest(String dartTestName) {
        this.dartTestName = dartTestName;
    }

    private final String dartTestName;

    @Test
    public void runDartTest() {
        PatrolJUnitRunner instrumentation =
                (PatrolJUnitRunner) InstrumentationRegistry.getInstrumentation();
        instrumentation.runDartTest(dartTestName);
    }
}
```

Khi copy sang project khác, phải sửa:

- Dòng `package com.example.your_app;`.
- Đường dẫn thư mục `java/com/example/your_app/`.
- Tên activity nếu app không dùng `MainActivity`.

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
~/.pub-cache/bin/patrol test -d emulator-5554 --target patrol_test/app_test.dart
```

Kết quả Patrol:

```text
Total: 4
Successful: 4
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
empty submit keeps No email submitted
replace first@example.com with second@example.com
tap incrementButton 20 times
verify Counter: 20
```

Android đã verify trên:

```text
Medium_Phone_API_36.1 / emulator-5554
Android 16 / API 36
patrol_cli v4.4.0
patrol package 4.6.1
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

Chạy emulator có sẵn:

```bash
flutter emulators
flutter emulators --launch <emulator_id>
adb wait-for-device
flutter devices
```

Ví dụ từ lần verify project này:

```bash
flutter emulators --launch Medium_Phone_API_36.1
adb wait-for-device
flutter devices
~/.pub-cache/bin/patrol test -d emulator-5554 --target patrol_test/app_test.dart
```

Kết quả Android đúng phải có `Total` lớn hơn 0. Với bộ test hiện tại của repo
này:

```text
Test summary:
Total: 4
Successful: 4
Failed: 0
Skipped: 0
```

Nếu thấy `Total: 0`, kiểm tra lại `MainActivityTest.java` trong
`androidTest`.

## 10. Tối Ưu Thời Gian Chạy Patrol Android Trên PC Khác

Patrol Android chậm hơn web/widget test là bình thường. Nó không chỉ chạy Dart
test, mà còn làm các bước Android native:

```text
generate patrol_test/test_bundle.dart
flutter build apk --config-only
Gradle assembleDebug
Gradle assembleDebugAndroidTest
ADB uninstall/install app APK
ADB uninstall/install androidTest APK
connectedDebugAndroidTest
PatrolJUnitRunner start app service
run Dart Patrol test
write Android test report
```

Trong project mẫu này, warm build sau khi emulator đã sẵn sàng khoảng 9 giây.
Tổng warm run Android cho 4 test hiện tại khoảng 2m46s. Các test case Dart riêng
lẻ mất khoảng 3-21 giây, phần còn lại là overhead của Android instrumentation,
orchestrator, install/uninstall và app service startup. Lần đầu trên PC mới có
thể mất vài phút, và với source lớn có thể lên 10-15 phút nếu cache chưa có hoặc
máy chậm.

### Nguyên Nhân Chậm Phổ Biến

- Cold build lần đầu: Flutter, Gradle, Kotlin/Java, Android transform/dex chưa
  có cache.
- Lần đầu sau khi đổi Flutter SDK, Android Gradle Plugin, Gradle wrapper,
  `compileSdk`, dependency hoặc Dart define.
- Emulator vừa boot, hệ thống Android chưa ổn định hoàn toàn.
- Gradle phải build cả app APK và androidTest APK.
- App có nhiều native plugin hoặc build nhiều ABI như `arm64-v8a`,
  `armeabi-v7a`, `x86_64`.
- Máy dùng disk chậm, RAM thấp, CPU ít core, hoặc chạy emulator không có
  hardware acceleration.
- Chạy `flutter clean` thường xuyên làm mất cache build.

### Checklist Setup PC Khác

1. Cài Flutter SDK đúng version của team.
2. Cài Android Studio hoặc Android command-line tools.
3. Cài Android SDK Platform, Build Tools, Platform Tools.
4. Accept licenses:

   ```bash
   flutter doctor --android-licenses
   ```

5. Kiểm tra môi trường:

   ```bash
   flutter doctor -v
   flutter devices
   ```

6. Cài Patrol CLI:

   ```bash
   dart pub global activate patrol_cli
   ~/.pub-cache/bin/patrol --version
   ```

7. Lấy dependency trước khi chạy E2E:

   ```bash
   flutter pub get
   ```

8. Chạy test rẻ trước:

   ```bash
   flutter analyze
   flutter test
   ```

9. Bật emulator và chờ device sẵn sàng:

   ```bash
   flutter emulators
   flutter emulators --launch <emulator_id>
   adb wait-for-device
   flutter devices
   ```

10. Chạy Patrol Android:

    ```bash
    ~/.pub-cache/bin/patrol test -d <device_id> --target patrol_test/app_test.dart
    ```

### Checklist Tối Ưu Khi Chạy Hằng Ngày

- Giữ emulator mở giữa các lần test.
- Không chạy `flutter clean` nếu không thật sự cần.
- Giữ `org.gradle.daemon=true`, `org.gradle.parallel=true`,
  `org.gradle.caching=true` trong `android/gradle.properties` nếu project phù
  hợp.
- Chạy lại cùng một emulator x86_64 ổn định, không đổi device liên tục.
- Nếu chỉ cần local smoke test, chạy một file target cụ thể:

  ```bash
  ~/.pub-cache/bin/patrol test -d emulator-5554 --target patrol_test/app_test.dart
  ```

- Với app lớn có native build chậm, cân nhắc giới hạn ABI debug cho local
  emulator x86_64. Chỉ làm việc này nếu team hiểu tác động release/build matrix.
- Không kỳ vọng việc gỡ app trong emulator làm build nhanh rõ rệt. Dọn app giúp
  giảm background noise/RAM, còn thời gian chính vẫn nằm ở Flutter/Gradle/ADB.
- Tránh để antivirus/indexer scan thư mục project, Gradle cache, Flutter cache
  trên Windows nếu build quá chậm.

### Khi Nào 15 Phút Là Bình Thường?

15 phút có thể xảy ra ở lần đầu trên source lớn khi:

- PC chưa có Gradle/Flutter cache.
- Project nhiều plugin native hoặc flavor.
- Emulator boot lần đầu.
- Internet/cache dependency chậm.
- Máy thiếu RAM nên Gradle/emulator bị swap.

Nếu sau 2-3 lần chạy cùng source, cùng emulator mà vẫn 15 phút, cần điều tra:

```bash
~/.pub-cache/bin/patrol test -d emulator-5554 --target patrol_test/app_test.dart --verbose
./gradlew :app:assembleDebug --profile
./gradlew :app:assembleDebugAndroidTest --profile
```

Xem task nào tốn thời gian trong Gradle profile report. Nếu log kẹt ở
`connectedDebugAndroidTest`, kiểm tra emulator/ADB/app startup. Nếu kẹt ở
`assembleDebug`, đó là build Flutter/Android. Nếu kẹt ở
`assembleDebugAndroidTest`, kiểm tra native test APK/dependency/desugar.

## 11. Pattern Viết Test Nên Dùng

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

## 12. Native Automation Trên Mobile

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

## 13. Debug Lỗi Thường Gặp

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

### Android chạy xong nhưng `Total: 0`

Nguyên nhân thường là thiếu native JUnit bridge trong `androidTest`, hoặc package
name/path không khớp.

Kiểm tra:

```text
android/app/src/androidTest/java/<package_path>/MainActivityTest.java
```

Trong verbose log, nếu thấy:

```text
compileDebugAndroidTestKotlin NO-SOURCE
compileDebugAndroidTestJavaWithJavac NO-SOURCE
```

thì Android test APK không có test class nào. Sau khi thêm
`MainActivityTest.java`, log phải có:

```text
compileDebugAndroidTestJavaWithJavac
```

và report phải có `Total` lớn hơn 0.

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

## 14. Checklist Apply Vào Dự Án Thật

1. Chạy `flutter analyze` để đảm bảo project sạch.
2. Cài/update Patrol CLI.
3. Thêm `patrol` vào `dev_dependencies`.
4. Thêm block `patrol:` vào `pubspec.yaml`.
5. Android: cấu hình `PatrolJUnitRunner` trong Gradle.
6. Android: thêm `MainActivityTest.java` trong `androidTest`.
7. Đặt `Key` cho các UI element quan trọng.
8. Tạo `patrol_test/app_test.dart`.
9. Viết smoke E2E flow ngắn nhất trước.
10. Chạy trên web bằng Chrome headless.
11. Nếu dự án mobile, chạy thêm Android/iOS device thật hoặc emulator.
12. Confirm report không phải `Total: 0`.
13. Thêm test vào CI sau khi local pass ổn định.
14. Ignore generated files của Patrol/Playwright.
15. Chỉ mở rộng E2E cho các flow quan trọng, không biến E2E thành test mọi chi tiết nhỏ.

## 15. Command Nhanh

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

# List and launch Android emulators
flutter emulators
flutter emulators --launch <emulator_id>
adb wait-for-device

# Run Patrol on a specific device
~/.pub-cache/bin/patrol test -d <device_id> --target patrol_test/app_test.dart

# Run Patrol Android with diagnostic logs
~/.pub-cache/bin/patrol test -d emulator-5554 --target patrol_test/app_test.dart --verbose
```
