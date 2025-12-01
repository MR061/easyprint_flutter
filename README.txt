EasyPrint Flutter Prototype

What this contains:
- pubspec.yaml
- lib/main.dart

How to use:
1. Install Flutter SDK on your machine (https://flutter.dev).
2. Run: flutter create easyprint_app
3. Replace the generated project's pubspec.yaml with this pubspec.yaml
4. Replace lib/main.dart with the provided lib/main.dart
5. Run: flutter pub get
6. Run on Android device/emulator: flutter run
7. To build APK: flutter build apk --release

Notes:
- This app uses file_picker to select PDF/image files and stores orders locally in SharedPreferences.
- No backend integrated. If you want Firebase backend, tell me and I will generate that version.
