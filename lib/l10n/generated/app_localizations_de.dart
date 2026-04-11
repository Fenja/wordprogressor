// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'WordProgressor';

  @override
  String get navProjects => 'Projekte';

  @override
  String get navDeadlines => 'Deadlines';

  @override
  String get navStats => 'Statistiken';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get projectsEmpty => 'Noch keine Projekte';

  @override
  String get projectsEmptyBody =>
      'Erstelle dein erstes Schreibprojekt und behalte Fortschritt und Deadlines im Blick.';

  @override
  String get addProject => 'Neues Projekt';

  @override
  String get editProject => 'Projekt bearbeiten';

  @override
  String get deleteProject => 'Projekt löschen';

  @override
  String get deleteProjectConfirmTitle => 'Projekt löschen?';

  @override
  String deleteProjectConfirmBody(String title) {
    return '\"$title\" wird dauerhaft gelöscht.';
  }

  @override
  String get fieldTitle => 'Titel';

  @override
  String get fieldGenre => 'Genre';

  @override
  String get fieldStatus => 'Status';

  @override
  String get fieldSynopsis => 'Synopsis';

  @override
  String get fieldWordGoal => 'Wortanzahl-Ziel';

  @override
  String get fieldChapters => 'Kapitelanzahl (geplant)';

  @override
  String get fieldDeadline => 'Deadline';

  @override
  String get fieldTags => 'Tags';

  @override
  String get fieldNotes => 'Notizen';

  @override
  String get fieldLanguage => 'Sprache';

  @override
  String get fieldStartDate => 'Begonnen am';

  @override
  String get fieldWords => 'Wörter';

  @override
  String get fieldDurationMin => 'Dauer (Min.)';

  @override
  String get statusDraft => 'Entwurf';

  @override
  String get statusActive => 'Aktiv';

  @override
  String get statusRevision => 'Überarbeitung';

  @override
  String get statusSubmitted => 'Eingereicht';

  @override
  String get statusAbandoned => 'Pausiert';

  @override
  String get deadlineNone => 'Keine Deadline';

  @override
  String deadlineDaysRemaining(int days) {
    return '$days Tage';
  }

  @override
  String get deadlineOverdue => 'Überfällig';

  @override
  String get milestoneEmpty => 'Noch keine Meilensteine';

  @override
  String get milestoneEmptyBody =>
      'Teile dein Projekt in überschaubare Schritte auf.';

  @override
  String get addMilestone => 'Meilenstein hinzufügen';

  @override
  String get milestoneDueDate => 'Fällig am';

  @override
  String get milestoneCompleted => 'Erledigt';

  @override
  String get milestonePending => 'Offen';

  @override
  String get logSession => 'Schreibsitzung erfassen';

  @override
  String get logWordsWritten => 'Geschriebene Wörter';

  @override
  String get logDuration => 'Dauer';

  @override
  String get logSessionNote => 'Notiz zur Sitzung';

  @override
  String get settingsAccount => 'Konto';

  @override
  String get settingsSync => 'Synchronisation';

  @override
  String get settingsAppearance => 'Darstellung';

  @override
  String get settingsNotifications => 'Benachrichtigungen';

  @override
  String get settingsAccessibility => 'Barrierefreiheit';

  @override
  String get settingsAbout => 'Über die App';

  @override
  String get settingsThemeLight => 'Hell';

  @override
  String get settingsThemeDark => 'Dunkel';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsSyncEnabled => 'Firebase-Synchronisation';

  @override
  String settingsSyncLast(String time) {
    return 'Zuletzt synchronisiert: $time';
  }

  @override
  String get settingsNotifDeadlines => 'Deadline-Erinnerungen';

  @override
  String get settingsNotifDeadlinesSub => 'Wird 3 Tage vor Ablauf erinnert';

  @override
  String get actionSave => 'Speichern';

  @override
  String get actionCancel => 'Abbrechen';

  @override
  String get actionDelete => 'Löschen';

  @override
  String get actionEdit => 'Bearbeiten';

  @override
  String get actionAdd => 'Hinzufügen';

  @override
  String get actionSignIn => 'Anmelden';

  @override
  String get actionSignOut => 'Abmelden';

  @override
  String get actionRegister => 'Konto erstellen';

  @override
  String get actionSyncNow => 'Jetzt synchronisieren';

  @override
  String get errorRequired => 'Dieses Feld ist erforderlich';

  @override
  String get errorInvalidEmail => 'Bitte eine gültige E-Mail-Adresse eingeben';

  @override
  String get errorPasswordTooShort => 'Mindestens 6 Zeichen';

  @override
  String get errorSaveFailed => 'Fehler beim Speichern';

  @override
  String progressPercent(int percent) {
    return '$percent% abgeschlossen';
  }

  @override
  String wordsOfGoal(String current, String goal) {
    return '$current / $goal Wörter';
  }

  @override
  String chapterProgress(int done, int total) {
    return 'Kapitel $done von $total';
  }
}
