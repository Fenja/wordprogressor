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



# Google & Apple Sign-In — Einrichtungsanleitung

## Übersicht der Änderungen

### Neue / geänderte Dateien

| Datei | Änderung |
|---|---|
| `pubspec.yaml` | `google_sign_in: ^6.2.1`, `sign_in_with_apple: ^6.1.1`, `crypto: ^3.0.3` |
| `lib/core/services/auth_service.dart` | Vollständig überarbeitet: Google + Apple + Email |
| `lib/features/settings/presentation/auth_screen.dart` | Google-Button, Apple-Button, E-Mail-Formular |
| `lib/features/settings/presentation/settings_screen.dart` | Zeigt Provider-Icon (Google/Apple/Email), echte User-Daten |
| `lib/features/settings/providers/settings_provider.dart` | `isLoggedInProvider` jetzt aus `auth_service.dart` |
| `android/app/src/main/res/values/strings.xml` | `default_web_client_id` Platzhalter |

---

## Schritt 1 — Google Sign-In (Firebase Console)

1. Firebase Console → **Authentication → Sign-in-Methode**
2. **Google** aktivieren
3. Projekt-Support-E-Mail auswählen
4. **Speichern**
5. Unter **„Web SDK-Konfiguration"** die **Web-Client-ID** kopieren
   (Format: `XXXXXXXX.apps.googleusercontent.com`)

---

## Schritt 2 — Google Sign-In (Android)

### SHA-1 Fingerprint hinterlegen

```bash
# Debug-Fingerprint (Entwicklung)
keytool -list -v -keystore ~/.android/debug.keystore \
        -alias androiddebugkey -storepass android -keypass android

# Release-Fingerprint (Play Store)
keytool -list -v -keystore /pfad/zu/release.keystore \
        -alias DEIN_ALIAS
```

Den SHA-1 in der Firebase Console hinterlegen:
**Projekteinstellungen → Deine Apps → Android-App → Fingerabdruck hinzufügen**

### google-services.json erneuern

Nach dem Hinzufügen des SHA-1 die `google-services.json` neu herunterladen
und unter `android/app/google-services.json` ablegen.

### strings.xml befüllen

In `android/app/src/main/res/values/strings.xml` den Platzhalter ersetzen:

```xml
<string name="default_web_client_id">
    DEINE_WEB_CLIENT_ID.apps.googleusercontent.com
</string>
```

Die Web-Client-ID stammt aus Schritt 1 (Firebase Console → Google → Web SDK-Konfiguration).

---

## Schritt 3 — Google Sign-In (iOS)

### URL-Schema eintragen

1. Xcode öffnen → `Runner.xcodeproj`
2. Target **Runner** → Tab **Info**
3. **URL Types** → `+` klicken
4. **URL Schemes**: `REVERSED_CLIENT_ID` aus `GoogleService-Info.plist`
   (Zeile `REVERSED_CLIENT_ID`, z.B. `com.googleusercontent.apps.XXXXXXXX`)

### Info.plist ergänzen

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- Aus GoogleService-Info.plist → REVERSED_CLIENT_ID -->
            <string>com.googleusercontent.apps.XXXXXXXX-YYYYYYYY</string>
        </array>
    </dict>
</array>
```

---

## Schritt 4 — Apple Sign-In (iOS / macOS)

### Capability aktivieren

1. Xcode → Target **Runner** → Tab **Signing & Capabilities**
2. **+ Capability** → **Sign in with Apple** hinzufügen
3. Xcode aktualisiert `Runner.entitlements` automatisch

### Firebase Console konfigurieren

1. Firebase Console → **Authentication → Sign-in-Methode**
2. **Apple** aktivieren
3. **Service-ID**: `com.example.wordprogressor` (muss mit Bundle-ID übereinstimmen)
4. **OAuth-Weiterleitungs-URI** aus Firebase kopieren:
   `https://wordprogressor.firebaseapp.com/__/auth/handler`
5. **Speichern**

### Apple Developer Portal

1. [developer.apple.com](https://developer.apple.com) → **Certificates, Identifiers & Profiles**
2. **Identifiers** → deine App-ID → **Sign In with Apple** aktivieren
3. **Services IDs** → neue Service-ID anlegen:
   - Identifier: `com.example.wordprogressor.siwa`
   - **Sign In with Apple** aktivieren
   - Domain: `wordprogressor.firebaseapp.com`
   - Return URL: `https://wordprogressor.firebaseapp.com/__/auth/handler`
4. **Keys** → neuen Key anlegen → **Sign In with Apple** aktivieren
   - Key-Datei (`.p8`) herunterladen (nur einmal möglich!)

### Key in Firebase hinterlegen

Firebase Console → Authentication → Apple → **Apple-Team-ID**, **Key-ID** und `.p8`-Datei hochladen.

---

## Schritt 5 — Apple Sign-In (Web)

Für Web benötigt Apple Sign-In dieselbe Service-ID und denselben OAuth-Callback
wie unter iOS. Kein zusätzlicher Code nötig — `AuthService.signInWithApple()`
verwendet auf Web automatisch `OAuthProvider('apple.com')` mit Firebase-Popup.

---

## Schritt 6 — FlutterFire neu konfigurieren

Nach allen Änderungen in der Firebase Console:

```bash
flutterfire configure
```

Dies aktualisiert `lib/firebase_options.dart` mit den aktuellen Werten.

---

## Schritt 7 — Testen

### Android (Google Sign-In)

```bash
flutter run -d android
```

→ Settings → Anmelden → „Mit Google anmelden"

Häufige Fehlerursachen:
- SHA-1 nicht in Firebase hinterlegt → `PlatformException: sign_in_failed`
- `google-services.json` veraltet → neu herunterladen
- `default_web_client_id` falsch → aus Firebase Console kopieren

### iOS (Google + Apple)

```bash
flutter run -d ios
```

Apple Sign-In funktioniert nur auf einem echten Gerät (nicht im Simulator)
— Apple verlangt eine aktive Internet-Verbindung zur Verifikation.

### Web

```bash
flutter run -d chrome
```

Beide Methoden verwenden Firebase-Popups — kein nativer SDK nötig.

---

## Fehlerbehandlung im Code

`AuthService._friendly()` übersetzt alle relevanten Firebase-Fehlercodes
in deutsche Nutzertexte:

| Firebase-Code | Angezeigter Text |
|---|---|
| `user-not-found` / `wrong-password` / `invalid-credential` | E-Mail oder Passwort ist falsch. |
| `email-already-in-use` | Diese E-Mail-Adresse wird bereits verwendet. |
| `weak-password` | Das Passwort muss mindestens 6 Zeichen lang sein. |
| `network-request-failed` | Keine Internetverbindung. |
| `cancelled` / `canceled` | Anmeldung abgebrochen. |
| Apple-Fehler | Apple Sign-In ist auf diesem Gerät nicht verfügbar. |