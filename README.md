# Family Tree App — Phase 1 Interactive Prototype

Flutter cross-platform prototype for a mock/local Family Tree application.

## What is implemented
- Mock Google sign-in that instantly authenticates a local Owner, Editor, or Viewer.
- Riverpod-based dependency injection with all screens using `FamilyRepository` only.
- Hive-backed mock persistence and first-launch seed data for a 3-generation sample family.
- Family creation, dynamic field schema setup, pannable/zoomable tree canvas, member profile/edit screens, photo zoom, appearance settings, and mocked collaborators/invites.
- Design decisions are centralized in `lib/theme/design_tokens.dart` and app theme wiring in `lib/theme/app_theme.dart`.

## What is mocked
- No real OAuth, MongoDB, realtime sync, email invite, or file upload service is called.
- Photos use remote placeholder URLs or text-entered mock paths.

## Run
```bash
flutter pub get
flutter run -d chrome
flutter run -d windows
flutter run -d macos
flutter run -d android
```

If desktop targets are not enabled locally, run:
```bash
flutter config --enable-windows-desktop --enable-macos-desktop
```
