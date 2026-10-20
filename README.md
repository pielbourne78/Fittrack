# FitTrack

FitTrack is an offline-first Flutter fitness tracker for web, Android, and iOS.
It replaces the Flask screens with a responsive Flutter interface and carries
the original profile, BMI/diet estimate, daily log, report, and rotating
four-day gym-program features into Dart.

## Run the app

Install Flutter, then run:

```sh
flutter pub get
flutter run -d chrome
```

For a connected Android device or emulator, use `flutter run -d <device-id>`.
iOS builds require macOS and Xcode.

## Features

- Local account registration and sign-in
- Profile, weight-goal, timeline, and BMI tracking
- Estimated calorie and macro targets
- Daily calorie and workout logging
- Progress reports and a repeating push/pull/legs/recovery program
- Persistent workout completion, profile, and log history

The app stores its data on the device using `flutter_secure_storage`; account
passwords are stored as salted PBKDF2 hashes. No server or cloud account is
used. On web, browser secure-storage support requires a secure origin such as
HTTPS or `localhost`. Clearing browser/site data can remove the local account
and its history.

Calorie, macro, BMI, and exercise-burn values are estimates for general
wellness tracking, not medical advice.

## Existing Flask data

The original Flask files and `instance/fittracks.db` are retained in the
repository, but the Flutter app does not call the Flask server or import that
database. Existing Flask accounts and logs are therefore not available in the
new Flutter app unless migrated separately.

## Validate

```sh
flutter analyze
flutter test
flutter build web
```
