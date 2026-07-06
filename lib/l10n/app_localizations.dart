import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

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
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// Title for the alarms screen
  ///
  /// In en, this message translates to:
  /// **'Alarms'**
  String get alarms;

  /// Title for the stopwatch screen
  ///
  /// In en, this message translates to:
  /// **'Stopwatch'**
  String get stopwatch;

  /// Button text to record a stopwatch lap
  ///
  /// In en, this message translates to:
  /// **'Lap'**
  String get lap;

  /// Button text to reset the stopwatch
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'Mechanix Clock'**
  String get mechanix_clock;

  /// Title for editing alarms
  ///
  /// In en, this message translates to:
  /// **'Edit Alarms'**
  String get edit_alarms;

  /// Message displayed when there are no alarms
  ///
  /// In en, this message translates to:
  /// **'No Alarms'**
  String get no_alarms;

  /// Label indicating an alarm repeats only once
  ///
  /// In en, this message translates to:
  /// **'Once'**
  String get once;

  /// Ante meridiem time indicator
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get am;

  /// Post meridiem time indicator
  ///
  /// In en, this message translates to:
  /// **'PM'**
  String get pm;

  /// Title for creating a new alarm
  ///
  /// In en, this message translates to:
  /// **'Set alarm'**
  String get set_alarm;

  /// Title for editing an existing alarm
  ///
  /// In en, this message translates to:
  /// **'Edit alarm'**
  String get edit_alarm;

  /// Label for alarm repeat settings
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// Label for alarm sound selection
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get sound;

  /// Label for alarm snooze setting
  ///
  /// In en, this message translates to:
  /// **'Snooze'**
  String get snooze;

  /// Full name of Monday
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// Full name of Tuesday
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// Full name of Wednesday
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// Full name of Thursday
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// Full name of Friday
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// Full name of Saturday
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// Full name of Sunday
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// Abbreviated label for Monday
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get monday_abbr;

  /// Abbreviated label for Tuesday
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get tuesday_abbr;

  /// Abbreviated label for Wednesday
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get wednesday_abbr;

  /// Abbreviated label for Thursday
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get thursday_abbr;

  /// Abbreviated label for Friday
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get friday_abbr;

  /// Abbreviated label for Saturday
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get saturday_abbr;

  /// Abbreviated label for Sunday
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get sunday_abbr;

  /// Label for a stopwatch lap with its sequence number
  ///
  /// In en, this message translates to:
  /// **'Lap {number}'**
  String lap_number(int number);

  /// Button text to stop the stopwatch
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// Button text to start the stopwatch
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// Placeholder message indicating the timer feature is not yet available
  ///
  /// In en, this message translates to:
  /// **'Timer - Coming Soon'**
  String get timer_coming_soon;

  /// Placeholder message indicating the world clock feature is not yet available
  ///
  /// In en, this message translates to:
  /// **'World Clock - Coming Soon'**
  String get world_clock_coming_soon;

  /// Title for the timers screen
  ///
  /// In en, this message translates to:
  /// **'Timers'**
  String get timers;

  /// Button text to cancel the timer
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Button text to pause the timer
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// Button text to resume the timer
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// Button text to dismiss the finished timer alert
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// Title for the finished timer alert
  ///
  /// In en, this message translates to:
  /// **'Timer Finished'**
  String get timer_finished;

  /// SnackBar message when the selected timer duration is already saved as a preset
  ///
  /// In en, this message translates to:
  /// **'Preset already exists'**
  String get timer_preset_exists;

  /// SnackBar message when trying to save a 0 duration preset
  ///
  /// In en, this message translates to:
  /// **'Please select a duration greater than 0'**
  String get timer_preset_invalid_duration;

  /// Button text to delete/cancel the running timer
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Label for naming a timer preset
  ///
  /// In en, this message translates to:
  /// **'Preset Name'**
  String get timer_preset_name;

  /// Hint text for timer preset name field
  ///
  /// In en, this message translates to:
  /// **'e.g. Tea, Workout, Study'**
  String get timer_preset_name_hint;

  /// Generic save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Title for editing a preset
  ///
  /// In en, this message translates to:
  /// **'Edit Preset'**
  String get edit_preset;

  /// Title for adding a preset
  ///
  /// In en, this message translates to:
  /// **'Add Preset'**
  String get add_preset;

  /// Abbreviated label for hours with a leading space
  ///
  /// In en, this message translates to:
  /// **' hrs'**
  String get hours_abbr;

  /// Abbreviated label for minutes with a leading space
  ///
  /// In en, this message translates to:
  /// **' mins'**
  String get minutes_abbr;

  /// Button text to restart the timer
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restart;
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
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
