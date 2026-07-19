# Family Tree App — Phase 1 Interactive Prototype

Flutter cross-platform prototype for a mock/local Family Tree application.

## ✨ Features Highlight
- **Dynamic Interactive Family Tree:** A beautiful, responsive, pannable, and zoomable DAG (Directed Acyclic Graph) canvas visualizing the entire family structure.
- **Smart Auto-Population Engine:** Context-aware adding logic. For example, adding a child to a married female automatically sets her as the mother and her spouse as the father.
- **Custom Labeled & Dotted Links:** Overlay custom relationship links (like 'Mentor' or 'Adopted') anywhere on the canvas with optional dotted paths.
- **Collapsible Subtrees:** Effortlessly explore deep family trees by collapsing or expanding individual family branches with smooth canvas updates.
- **Intelligent Member Form:** Automatically calculates age instantly based on DOB, dynamically shows/hides maiden names based on gender, and mandates required fields.
- **Dynamic Persona Icons:** Default avatars are smartly auto-assigned based on age, gender, and profession.
- **Beautiful Premium UI:** Completely custom-designed card interfaces, smooth modal overlays, and centralized design tokens for a gorgeous aesthetic.
- **Collaborator Invites:** Easily invite other family members via email directly from their profile screen.
- **Dependency Injection & Local Persistence:** Built solidly on Riverpod and Hive, supporting instant offline mock usage and seeding.

## What is mocked
- No real OAuth, MongoDB, realtime sync, email invite, or file upload service is called.
- Photos use remote placeholder URLs or base64 strings.

## Platforms
```bash
flutter create . --platforms web
flutter create . --platforms android
```

## Run
```bash
flutter pub get
flutter run -d chrome
flutter run -d edge
flutter run -d windows
flutter run -d macos
flutter run -d android
```

If desktop targets are not enabled locally, run:
```bash
flutter create --platforms=windows .
flutter config --enable-windows-desktop --enable-macos-desktop

# manually enable Developer Mode in your system settings
start ms-settings:developers
```
