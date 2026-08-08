# EVENTO Phone Build Status

Commit: d3ccf8338d1a58562b5919714255f6d88a8d2fd6
Run number: 6
Job status: failure
Failed stage: source_patch
Updated: 2026-08-08T22:29:53Z

## Step outcomes
- Flutter install: success
- Android wrapper: success
- Source patch: failure
- Signing: skipped
- Pub get: skipped
- Analyze: skipped
- Tests: skipped
- Build: skipped
- Artifact: skipped
- Release: skipped

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
Expected account signed-in block was not found.
```
