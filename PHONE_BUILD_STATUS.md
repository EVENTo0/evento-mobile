# EVENTO Phone Build Status

Commit: 282343e2617564241333e053f8e72f1dcb378a41
Run number: 1
Job status: failure
Failed stage: analyze
Target: lib/main_rc3_v2.dart
Channel: RC3 v2 phone-safe update
Updated: 2026-08-09T00:28:54Z

## Step outcomes
- Flutter install: success
- Android wrapper: success
- Source patch: success
- Signing: success
- Pub get: success
- Analyze: failure
- Tests: skipped
- Build: skipped
- Artifact: skipped
- Release: skipped

## Diagnostic tail
```text
===== ci-logs/01-flutter.log =====
+ source_maps 0.10.13
+ source_span 1.10.2
+ sprintf 7.0.0
+ sse 4.1.8 (4.2.0 available)
+ stack_trace 1.12.1
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
  android/settings.gradle.kts (created)
  android/app/src/debug/AndroidManifest.xml (created)
  android/app/src/profile/AndroidManifest.xml (created)
  android/app/src/main/res/values/styles.xml (created)
  android/app/src/main/res/mipmap-hdpi/ic_launcher.png (created)
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

===== ci-logs/03-source.log =====
RC3 v2 entrypoint uses publishableKey natively; bootstrap fallback normalized for analysis.
===== ci-logs/04-signing.log =====
androiddebugkey, Aug 8, 2026, PrivateKeyEntry, 
Certificate fingerprint (SHA-256): BA:C5:A3:17:AC:D9:28:6A:A3:46:26:8D:AF:F0:46:3D:AE:65:39:32:F4:83:84:5E:12:99:55:DE:4D:06:9A:36
===== ci-logs/05-pub-get.log =====
+ postgrest 2.8.0 (2.9.1 available)
+ realtime_client 2.11.0 (2.13.0 available)
+ retry 3.1.2
+ rxdart 0.28.0
+ shared_preferences 2.5.5
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

   info • Statements in an if should be enclosed in a block. Try wrapping the statement in a block • lib/rc3_app.dart:459:22 • curly_braces_in_flow_control_structures
   info • Statements in an if should be enclosed in a block. Try wrapping the statement in a block • lib/rc3_app.dart:466:20 • curly_braces_in_flow_control_structures

2 issues found. (ran in 9.7s)
```
