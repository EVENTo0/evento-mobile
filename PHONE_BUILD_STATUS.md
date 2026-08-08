# EVENTO Phone Build Status

Commit: 932350464dc7058d2ea50d804408ba927735fae7
Run number: 7
Job status: success
Failed stage: none
Updated: 2026-08-08T22:37:19Z

## Step outcomes
- Flutter install: success
- Android wrapper: success
- Source patch: success
- Signing: success
- Pub get: success
- Analyze: success
- Tests: success
- Build: success
- Artifact: success
- Release: success

## Diagnostic tail
```text
===== ci-logs/01-flutter-install.log =====
+ standard_message_codec 0.0.1+4 (0.0.1+5 available)
+ stream_channel 2.1.4
+ string_scanner 1.4.1
+ sync_http 0.3.1
+ term_glyph 1.2.2
+ test 1.31.0 (1.31.2 available)
+ test_api 0.7.11 (0.7.13 available)
+ test_core 0.6.17 (0.6.19 available)
+ typed_data 1.4.0
+ unified_analytics 8.0.14 (8.0.16 available)
+ usage 4.1.1 (discontinued)
+ uuid 4.5.3 (4.6.0 available)
+ vm_service 15.0.2 (15.2.0 available)
+ vm_service_interface 2.0.1
+ vm_snapshot_analysis 0.7.6
+ watcher 1.2.1
+ web 1.1.1
+ web_socket 1.0.1
+ web_socket_channel 3.0.3
+ webdriver 3.1.0
+ webkit_inspection_protocol 1.2.1
+ xml 6.6.1 (7.0.1 available)
+ yaml 3.1.3
+ yaml_edit 2.2.4
Changed 102 dependencies!
2 packages are discontinued.
32 packages have newer versions incompatible with dependency constraints.
Try `dart pub outdated` for more information.
Analytics reporting disabled.

You may need to restart any open editors for them to read new settings.
Flutter 3.44.9 • channel [user-branch] • unknown source
Framework • revision 6b182d2c75 (3 days ago) • 2026-08-05 10:04:07 -0700
Engine • hash b9499e4c25212536ba3a4eec4f5c1905fb3214fe (revision 5a2a6a42cc) (8 days ago) • 2026-07-31 18:31:59.000Z
Tools • Dart 3.12.2 • DevTools 2.57.0
===== ci-logs/02-android-wrapper.log =====
  android/app/src/main/res/mipmap-xhdpi/ic_launcher.png (created)
  android/app/src/main/res/drawable-v21/launch_background.xml (created)
  android/app/src/main/res/drawable/launch_background.xml (created)
  android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png (created)
  android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png (created)
  android/app/src/main/res/mipmap-mdpi/ic_launcher.png (created)
  android/app/src/main/res/values-night/styles.xml (created)
  android/app/src/main/AndroidManifest.xml (created)
  android/gradle.properties (created)
  android/gradle/wrapper/gradle-wrapper.properties (created)
  android/.gitignore (created)
  evento_mobile.iml (created)
  .idea/workspace.xml (created)
  .idea/runConfigurations/main_dart.xml (created)
  .idea/libraries/Dart_SDK.xml (created)
  .idea/libraries/KotlinJavaRuntime.xml (created)
  .idea/modules.xml (created)
  android/build.gradle.kts (created)
  android/app/build.gradle.kts (created)
  android/app/src/main/kotlin/ae/evento/evento_mobile/MainActivity.kt (created)
  android/evento_mobile_android.iml (created)
  .gitignore (created)
Wrote 30 files.

All done!
You can find general documentation for Flutter at: https://docs.flutter.dev/
Detailed API documentation is available at: https://api.flutter.dev/
If you prefer video documentation, consider: https://www.youtube.com/c/flutterdev

In order to run your application, type:

  $ flutter run

Your application code is in ./lib/main.dart.

===== ci-logs/03-source-patch.log =====
Supabase initialization uses publishableKey. Account null-safety source left intact.
===== ci-logs/04-signing.log =====
androiddebugkey, Aug 8, 2026, PrivateKeyEntry, 
Certificate fingerprint (SHA-256): BA:C5:A3:17:AC:D9:28:6A:A3:46:26:8D:AF:F0:46:3D:AE:65:39:32:F4:83:84:5E:12:99:55:DE:4D:06:9A:36
===== ci-logs/05-pub-get.log =====
+ shared_preferences_android 2.4.27
+ shared_preferences_foundation 2.5.6
+ shared_preferences_linux 2.4.1
+ shared_preferences_platform_interface 2.4.2
+ shared_preferences_web 2.4.3
+ shared_preferences_windows 2.4.1
+ sky_engine 0.0.0 from sdk flutter
+ source_span 1.10.2
+ stack_trace 1.12.1
+ storage_client 2.6.0 (2.8.0 available)
+ stream_channel 2.1.4
+ string_scanner 1.4.1
+ supabase 2.14.0 (2.16.0 available)
+ supabase_flutter 2.16.0 (2.17.1 available)
+ term_glyph 1.2.2
+ test_api 0.7.11 (0.7.13 available)
+ typed_data 1.4.0
+ url_launcher 6.3.2
+ url_launcher_android 6.3.32
+ url_launcher_ios 6.4.1
+ url_launcher_linux 3.2.2
+ url_launcher_macos 3.2.5
+ url_launcher_platform_interface 2.3.2
+ url_launcher_web 2.4.3
+ url_launcher_windows 3.1.5
  vector_math 2.2.0 (from direct dependency to transitive dependency) (2.4.2 available)
+ vm_service 15.2.0
+ web 1.1.1
+ web_socket 1.0.1
+ web_socket_channel 3.0.3
+ xdg_directories 1.1.0
+ yet_another_json_isolate 2.1.1
Changed 80 dependencies!
11 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
===== ci-logs/06-analyze.log =====
Analyzing evento-mobile...                                      
No issues found! (ran in 6.9s)
===== ci-logs/07-tests.log =====
00:00 +0: loading /home/runner/work/evento-mobile/evento-mobile/test/widget_test.dart
00:00 +0: EVENTO shell loads and navigates to request
00:00 +1: language toggle switches navigation labels
00:01 +2: All tests passed!
===== ci-logs/08-build.log =====
[1/1] Android SDK
  ├─ [1/6] android-arm-profile/linux-x64                           281ms
  ├─ [2/6] android-arm-release/linux-x64                           127ms
  ├─ [3/6] android-arm64-profile/linux-x64                         139ms
  ├─ [4/6] android-arm64-release/linux-x64                         115ms
  ├─ [5/6] android-x64-profile/linux-x64                           125ms
  └─ [6/6] android-x64-release/linux-x64                           107ms
Running Gradle task 'assembleDebug'...                          
Checking the license for package CMake 3.22.1 in /usr/local/lib/android/sdk/licenses
License for package CMake 3.22.1 accepted.
Preparing "Install CMake 3.22.1 v.3.22.1".
"Install CMake 3.22.1 v.3.22.1" ready.
Installing CMake 3.22.1 in /usr/local/lib/android/sdk/cmake/3.22.1
"Install CMake 3.22.1 v.3.22.1" complete.
"Install CMake 3.22.1 v.3.22.1" finished.
Running Gradle task 'assembleDebug'...                            310.0s
✓ Built build/app/outputs/flutter-apk/app-debug.apk
===== ci-logs/09-release.log =====
https://github.com/EVENTo0/evento-mobile/releases/tag/dev-latest
```
