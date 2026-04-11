import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// The app name
  ///
  /// In de, this message translates to:
  /// **'WordProgressor'**
  String get appTitle;

  /// No description provided for @navProjects.
  ///
  /// In de, this message translates to:
  /// **'Projekte'**
  String get navProjects;

  /// No description provided for @navDeadlines.
  ///
  /// In de, this message translates to:
  /// **'Deadlines'**
  String get navDeadlines;

  /// No description provided for @navStats.
  ///
  /// In de, this message translates to:
  /// **'Statistiken'**
  String get navStats;

  /// No description provided for @navSettings.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get navSettings;

  /// No description provided for @projectsEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Projekte'**
  String get projectsEmpty;

  /// No description provided for @projectsEmptyBody.
  ///
  /// In de, this message translates to:
  /// **'Erstelle dein erstes Schreibprojekt und behalte Fortschritt und Deadlines im Blick.'**
  String get projectsEmptyBody;

  /// No description provided for @addProject.
  ///
  /// In de, this message translates to:
  /// **'Neues Projekt'**
  String get addProject;

  /// No description provided for @editProject.
  ///
  /// In de, this message translates to:
  /// **'Projekt bearbeiten'**
  String get editProject;

  /// No description provided for @deleteProject.
  ///
  /// In de, this message translates to:
  /// **'Projekt löschen'**
  String get deleteProject;

  /// No description provided for @deleteProjectConfirmTitle.
  ///
  /// In de, this message translates to:
  /// **'Projekt löschen?'**
  String get deleteProjectConfirmTitle;

  /// No description provided for @deleteProjectConfirmBody.
  ///
  /// In de, this message translates to:
  /// **'\"{title}\" wird dauerhaft gelöscht.'**
  String deleteProjectConfirmBody(String title);

  /// No description provided for @fieldTitle.
  ///
  /// In de, this message translates to:
  /// **'Titel'**
  String get fieldTitle;

  /// No description provided for @fieldGenre.
  ///
  /// In de, this message translates to:
  /// **'Genre'**
  String get fieldGenre;

  /// No description provided for @fieldStatus.
  ///
  /// In de, this message translates to:
  /// **'Status'**
  String get fieldStatus;

  /// No description provided for @fieldSynopsis.
  ///
  /// In de, this message translates to:
  /// **'Synopsis'**
  String get fieldSynopsis;

  /// No description provided for @fieldWordGoal.
  ///
  /// In de, this message translates to:
  /// **'Wortanzahl-Ziel'**
  String get fieldWordGoal;

  /// No description provided for @fieldChapters.
  ///
  /// In de, this message translates to:
  /// **'Kapitelanzahl (geplant)'**
  String get fieldChapters;

  /// No description provided for @fieldDeadline.
  ///
  /// In de, this message translates to:
  /// **'Deadline'**
  String get fieldDeadline;

  /// No description provided for @fieldTags.
  ///
  /// In de, this message translates to:
  /// **'Tags'**
  String get fieldTags;

  /// No description provided for @fieldNotes.
  ///
  /// In de, this message translates to:
  /// **'Notizen'**
  String get fieldNotes;

  /// No description provided for @fieldLanguage.
  ///
  /// In de, this message translates to:
  /// **'Sprache'**
  String get fieldLanguage;

  /// No description provided for @fieldStartDate.
  ///
  /// In de, this message translates to:
  /// **'Begonnen am'**
  String get fieldStartDate;

  /// No description provided for @fieldWords.
  ///
  /// In de, this message translates to:
  /// **'Wörter'**
  String get fieldWords;

  /// No description provided for @fieldDurationMin.
  ///
  /// In de, this message translates to:
  /// **'Dauer (Min.)'**
  String get fieldDurationMin;

  /// No description provided for @statusDraft.
  ///
  /// In de, this message translates to:
  /// **'Entwurf'**
  String get statusDraft;

  /// No description provided for @statusActive.
  ///
  /// In de, this message translates to:
  /// **'Aktiv'**
  String get statusActive;

  /// No description provided for @statusRevision.
  ///
  /// In de, this message translates to:
  /// **'Überarbeitung'**
  String get statusRevision;

  /// No description provided for @statusSubmitted.
  ///
  /// In de, this message translates to:
  /// **'Eingereicht'**
  String get statusSubmitted;

  /// No description provided for @statusAbandoned.
  ///
  /// In de, this message translates to:
  /// **'Pausiert'**
  String get statusAbandoned;

  /// No description provided for @deadlineNone.
  ///
  /// In de, this message translates to:
  /// **'Keine Deadline'**
  String get deadlineNone;

  /// No description provided for @deadlineDaysRemaining.
  ///
  /// In de, this message translates to:
  /// **'{days} Tage'**
  String deadlineDaysRemaining(int days);

  /// No description provided for @deadlineOverdue.
  ///
  /// In de, this message translates to:
  /// **'Überfällig'**
  String get deadlineOverdue;

  /// No description provided for @milestoneEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Meilensteine'**
  String get milestoneEmpty;

  /// No description provided for @milestoneEmptyBody.
  ///
  /// In de, this message translates to:
  /// **'Teile dein Projekt in überschaubare Schritte auf.'**
  String get milestoneEmptyBody;

  /// No description provided for @addMilestone.
  ///
  /// In de, this message translates to:
  /// **'Meilenstein hinzufügen'**
  String get addMilestone;

  /// No description provided for @milestoneDueDate.
  ///
  /// In de, this message translates to:
  /// **'Fällig am'**
  String get milestoneDueDate;

  /// No description provided for @milestoneCompleted.
  ///
  /// In de, this message translates to:
  /// **'Erledigt'**
  String get milestoneCompleted;

  /// No description provided for @milestonePending.
  ///
  /// In de, this message translates to:
  /// **'Offen'**
  String get milestonePending;

  /// No description provided for @logSession.
  ///
  /// In de, this message translates to:
  /// **'Schreibsitzung erfassen'**
  String get logSession;

  /// No description provided for @logWordsWritten.
  ///
  /// In de, this message translates to:
  /// **'Geschriebene Wörter'**
  String get logWordsWritten;

  /// No description provided for @logDuration.
  ///
  /// In de, this message translates to:
  /// **'Dauer'**
  String get logDuration;

  /// No description provided for @logSessionNote.
  ///
  /// In de, this message translates to:
  /// **'Notiz zur Sitzung'**
  String get logSessionNote;

  /// No description provided for @settingsAccount.
  ///
  /// In de, this message translates to:
  /// **'Konto'**
  String get settingsAccount;

  /// No description provided for @settingsSync.
  ///
  /// In de, this message translates to:
  /// **'Synchronisation'**
  String get settingsSync;

  /// No description provided for @settingsAppearance.
  ///
  /// In de, this message translates to:
  /// **'Darstellung'**
  String get settingsAppearance;

  /// No description provided for @settingsNotifications.
  ///
  /// In de, this message translates to:
  /// **'Benachrichtigungen'**
  String get settingsNotifications;

  /// No description provided for @settingsAccessibility.
  ///
  /// In de, this message translates to:
  /// **'Barrierefreiheit'**
  String get settingsAccessibility;

  /// No description provided for @settingsAbout.
  ///
  /// In de, this message translates to:
  /// **'Über die App'**
  String get settingsAbout;

  /// No description provided for @settingsThemeLight.
  ///
  /// In de, this message translates to:
  /// **'Hell'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In de, this message translates to:
  /// **'Dunkel'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In de, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsSyncEnabled.
  ///
  /// In de, this message translates to:
  /// **'Firebase-Synchronisation'**
  String get settingsSyncEnabled;

  /// No description provided for @settingsSyncLast.
  ///
  /// In de, this message translates to:
  /// **'Zuletzt synchronisiert: {time}'**
  String settingsSyncLast(String time);

  /// No description provided for @settingsNotifDeadlines.
  ///
  /// In de, this message translates to:
  /// **'Deadline-Erinnerungen'**
  String get settingsNotifDeadlines;

  /// No description provided for @settingsNotifDeadlinesSub.
  ///
  /// In de, this message translates to:
  /// **'Wird 3 Tage vor Ablauf erinnert'**
  String get settingsNotifDeadlinesSub;

  /// No description provided for @actionSave.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get actionSave;

  /// No description provided for @actionCancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get actionCancel;

  /// No description provided for @actionDelete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get actionDelete;

  /// No description provided for @actionEdit.
  ///
  /// In de, this message translates to:
  /// **'Bearbeiten'**
  String get actionEdit;

  /// No description provided for @actionAdd.
  ///
  /// In de, this message translates to:
  /// **'Hinzufügen'**
  String get actionAdd;

  /// No description provided for @actionSignIn.
  ///
  /// In de, this message translates to:
  /// **'Anmelden'**
  String get actionSignIn;

  /// No description provided for @actionSignOut.
  ///
  /// In de, this message translates to:
  /// **'Abmelden'**
  String get actionSignOut;

  /// No description provided for @actionRegister.
  ///
  /// In de, this message translates to:
  /// **'Konto erstellen'**
  String get actionRegister;

  /// No description provided for @actionSyncNow.
  ///
  /// In de, this message translates to:
  /// **'Jetzt synchronisieren'**
  String get actionSyncNow;

  /// No description provided for @errorRequired.
  ///
  /// In de, this message translates to:
  /// **'Dieses Feld ist erforderlich'**
  String get errorRequired;

  /// No description provided for @errorInvalidEmail.
  ///
  /// In de, this message translates to:
  /// **'Bitte eine gültige E-Mail-Adresse eingeben'**
  String get errorInvalidEmail;

  /// No description provided for @errorPasswordTooShort.
  ///
  /// In de, this message translates to:
  /// **'Mindestens 6 Zeichen'**
  String get errorPasswordTooShort;

  /// No description provided for @errorSaveFailed.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Speichern'**
  String get errorSaveFailed;

  /// No description provided for @progressPercent.
  ///
  /// In de, this message translates to:
  /// **'{percent}% abgeschlossen'**
  String progressPercent(int percent);

  /// No description provided for @wordsOfGoal.
  ///
  /// In de, this message translates to:
  /// **'{current} / {goal} Wörter'**
  String wordsOfGoal(String current, String goal);

  /// No description provided for @chapterProgress.
  ///
  /// In de, this message translates to:
  /// **'Kapitel {done} von {total}'**
  String chapterProgress(int done, int total);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
