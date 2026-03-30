# WordProgressor

Eine Flutter-App zur Verwaltung von kreativen Schreibprojekten – mit Metadaten, Fortschrittsverfolgung, Meilensteinen und Deadline-Management.

## Features

- **Projektmanagement** – Titel, Genre, Tags, Synopsis, Sprache, Zielgruppe
- **Fortschrittsverfolgung** – Wortanzahl, Kapitel, Schreibsitzungen
- **Meilensteine** – benutzerdefiniert, sortierbar, mit Fälligkeitsdatum
- **Deadlines** – Ampelstatus (OK / bald / überfällig), lokale Push-Benachrichtigungen
- **Offline-First** – vollständig nutzbar ohne Konto und ohne Internet (SQLite via Drift)
- **Cloud-Sync** – optional mit Firebase Auth + Firestore
- **Barrierefreiheit** – WCAG 2.2, TalkBack/VoiceOver, dynamische Schriftgröße, hoher Kontrast

---

## Voraussetzungen

- Flutter SDK ≥ 3.22 ([flutter.dev](https://flutter.dev))
- Dart SDK ≥ 3.3
- Android Studio oder Xcode (für Emulator/Simulator)

---

## Einrichtung

### 1. Abhängigkeiten installieren

```bash
flutter pub get
```

### 2. Code generieren

Drift-Datenbankschema, Riverpod-Provider und Freezed-Modelle werden per
`build_runner` generiert. Beim ersten Setup und nach Schemaänderungen ausführen:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Für Watch-Modus während der Entwicklung:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

### 3. App starten

```bash
flutter run
```

---

## Firebase einrichten (optional – nur für Cloud-Sync)

1. Firebase-Projekt anlegen unter [console.firebase.google.com](https://console.firebase.google.com)
2. Android- und iOS-App hinzufügen
3. `google-services.json` → `android/app/`
4. `GoogleService-Info.plist` → `ios/Runner/`
5. Firebase CLI installieren: `npm install -g firebase-tools`
6. FlutterFire konfigurieren:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

Ohne Firebase funktioniert die App vollständig im Offline-Modus. Der Sync-Button in den Einstellungen ist dann deaktiviert.

### Firestore Security Rules (Beispiel)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## Projektstruktur

```
lib/
├── app/               # App-Widget, Router (go_router)
├── core/
│   ├── database/      # Drift-Datenbankschema + DAOs
│   ├── services/      # SyncService, AuthService, NotificationService
│   └── theme/         # Material 3 AppTheme, AppColors
└── features/
    ├── projects/      # Projektliste, Detail, Formular, Repository, Provider
    ├── milestones/    # Meilenstein-Verwaltung
    ├── deadlines/     # Deadline-Übersicht
    ├── stats/         # Schreibstatistiken
    └── settings/      # Einstellungen, Theme, Sync, Auth
```

---

## Barrierefreiheit

- Alle interaktiven Elemente haben `Semantics`-Labels
- Touch-Targets sind mindestens 48 × 48 dp
- Textgröße folgt der Systemeinstellung (max. 1,4×)
- Farben erfüllen WCAG AA (Kontrast ≥ 4,5:1)
- Animationen respektieren `reduceMotion`
- VoiceOver (iOS) und TalkBack (Android) getestet

---

## Build-Befehle

```bash
# Debug-Build
flutter run

# Release-Build Android
flutter build apk --release
flutter build appbundle --release

# Release-Build iOS
flutter build ios --release

# Tests
flutter test

# Linter
flutter analyze
```

---

## Lizenz

MIT