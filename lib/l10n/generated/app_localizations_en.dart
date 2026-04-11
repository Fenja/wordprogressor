// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'WordProgressor';

  @override
  String get navProjects => 'Projects';

  @override
  String get navDeadlines => 'Deadlines';

  @override
  String get navStats => 'Statistics';

  @override
  String get navSettings => 'Settings';

  @override
  String get projectsEmpty => 'No projects yet';

  @override
  String get projectsEmptyBody =>
      'Create your first writing project and track your progress and deadlines.';

  @override
  String get addProject => 'New project';

  @override
  String get editProject => 'Edit project';

  @override
  String get deleteProject => 'Delete project';

  @override
  String get deleteProjectConfirmTitle => 'Delete project?';

  @override
  String deleteProjectConfirmBody(String title) {
    return '\"$title\" will be permanently deleted.';
  }

  @override
  String get fieldTitle => 'Title';

  @override
  String get fieldGenre => 'Genre';

  @override
  String get fieldStatus => 'Status';

  @override
  String get fieldSynopsis => 'Synopsis';

  @override
  String get fieldWordGoal => 'Word count goal';

  @override
  String get fieldChapters => 'Chapter count (planned)';

  @override
  String get fieldDeadline => 'Deadline';

  @override
  String get fieldTags => 'Tags';

  @override
  String get fieldNotes => 'Notes';

  @override
  String get fieldLanguage => 'Language';

  @override
  String get fieldStartDate => 'Started on';

  @override
  String get fieldWords => 'Words';

  @override
  String get fieldDurationMin => 'Duration (min)';

  @override
  String get statusDraft => 'Draft';

  @override
  String get statusActive => 'Active';

  @override
  String get statusRevision => 'Revision';

  @override
  String get statusSubmitted => 'Submitted';

  @override
  String get statusAbandoned => 'Paused';

  @override
  String get deadlineNone => 'No deadline';

  @override
  String deadlineDaysRemaining(int days) {
    return '$days days';
  }

  @override
  String get deadlineOverdue => 'Overdue';

  @override
  String get milestoneEmpty => 'No milestones yet';

  @override
  String get milestoneEmptyBody => 'Break your project into manageable steps.';

  @override
  String get addMilestone => 'Add milestone';

  @override
  String get milestoneDueDate => 'Due date';

  @override
  String get milestoneCompleted => 'Completed';

  @override
  String get milestonePending => 'Pending';

  @override
  String get logSession => 'Log writing session';

  @override
  String get logWordsWritten => 'Words written';

  @override
  String get logDuration => 'Duration';

  @override
  String get logSessionNote => 'Session note';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsSync => 'Synchronisation';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsAccessibility => 'Accessibility';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsSyncEnabled => 'Firebase sync';

  @override
  String settingsSyncLast(String time) {
    return 'Last synced: $time';
  }

  @override
  String get settingsNotifDeadlines => 'Deadline reminders';

  @override
  String get settingsNotifDeadlinesSub => 'Reminded 3 days before due date';

  @override
  String get actionSave => 'Save';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionSignIn => 'Sign in';

  @override
  String get actionSignOut => 'Sign out';

  @override
  String get actionRegister => 'Create account';

  @override
  String get actionSyncNow => 'Sync now';

  @override
  String get errorRequired => 'This field is required';

  @override
  String get errorInvalidEmail => 'Please enter a valid email address';

  @override
  String get errorPasswordTooShort => 'At least 6 characters required';

  @override
  String get errorSaveFailed => 'Failed to save';

  @override
  String progressPercent(int percent) {
    return '$percent% complete';
  }

  @override
  String wordsOfGoal(String current, String goal) {
    return '$current / $goal words';
  }

  @override
  String chapterProgress(int done, int total) {
    return 'Chapter $done of $total';
  }
}
