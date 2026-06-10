# Smart Price Alert — Android Notification Setup

## Required AndroidManifest.xml permissions

Add these permissions to `android/app/src/main/AndroidManifest.xml`
(inside the `<manifest>` tag, before `<application>`):

```xml
<!-- Smart Price Alert: notification permission (Android 13+) -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<!-- Smart Price Alert: exact alarm scheduling -->
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
```

## Full AndroidManifest.xml reference

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Standard Flutter permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>

    <!-- Smart Price Alert v2 — notification permissions -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>

    <application
        android:label="NEONCRED"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme"/>
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <meta-data
            android:name="flutterEmbedding"
            android:value="2"/>
    </application>
</manifest>
```

## Runtime permission request (Android 13+)

The app must also request notification permission at runtime.
This is handled in `smart_alerts_service.dart` via `flutter_local_notifications`.

For production, add this to the screen's `initState`:

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> requestNotificationPermission() async {
  final plugin = FlutterLocalNotificationsPlugin();
  final androidPlugin = plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  if (androidPlugin != null) {
    await androidPlugin.requestNotificationsPermission();
  }
}
```
