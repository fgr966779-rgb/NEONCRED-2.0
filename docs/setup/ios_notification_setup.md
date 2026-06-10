# Smart Price Alert — iOS Notification Setup

## Required Info.plist key

Add this key to `ios/Runner/Info.plist` (inside the top-level `<dict>`):

```xml
<!-- Smart Price Alert: notification usage description -->
<key>NSUserNotificationsUsageDescription</key>
<string>NEONCRED needs notifications to alert you when product prices drop to your target.</string>
```

## Full Info.plist reference

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Standard Flutter keys -->
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleDisplayName</key>
    <string>NEONCRED</string>
    <key>CFBundleExecutable</key>
    <string>Runner</string>
    <key>CFBundleIdentifier</key>
    <string>com.neoncred.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>NEONCRED</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>2.0.0</string>
    <key>CFBundleVersion</key>
    <string>28</string>

    <!-- Smart Price Alert v2 — notification permission -->
    <key>NSUserNotificationsUsageDescription</key>
    <string>NEONCRED needs notifications to alert you when product prices drop to your target.</string>

    <key>UILaunchStoryboardName</key>
    <string>LaunchScreen</string>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
    </array>
    <key>UIViewControllerBasedStatusBarAppearance</key>
    <false/>
</dict>
</plist>
```

## Runtime permission request (iOS)

iOS requires requesting notification authorization at runtime.
This is handled in `smart_alerts_service.dart` via `flutter_local_notifications`.

The `DarwinInitializationSettings` in the service already includes
the default notification categories. For production, you may want to
add:

```dart
const iosSettings = DarwinInitializationSettings(
  requestAlertPermission: true,
  requestBadgePermission: true,
  requestSoundPermission: true,
);
```
