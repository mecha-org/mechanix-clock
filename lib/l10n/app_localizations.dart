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
  /// **'ALARMS'**
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

  /// Message displayed when there are no alarms
  ///
  /// In en, this message translates to:
  /// **'NO ALARMS'**
  String get no_alarms;

  /// Label indicating an alarm repeats only once
  ///
  /// In en, this message translates to:
  /// **'Once'**
  String get once;

  /// Label indicating an alarm repeats daily
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// Label indicating an alarm has custom repeat days
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// Label indicating the default setting
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get default_label;

  /// Label for the alarm time row
  ///
  /// In en, this message translates to:
  /// **'Alarm time'**
  String get alarm_time;

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

  /// Uppercase label for a stopwatch lap with padded number
  ///
  /// In en, this message translates to:
  /// **'LAP {number}'**
  String lap_padded(String number);

  /// Button text to start the stopwatch
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// Title for the timers screen
  ///
  /// In en, this message translates to:
  /// **'Timer'**
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

  /// Button text to delete/cancel the running timer
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Generic save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Abbreviated label for single hour with a leading space
  ///
  /// In en, this message translates to:
  /// **' hr'**
  String get hour_abbr;

  /// Abbreviated label for hours with a leading space
  ///
  /// In en, this message translates to:
  /// **' hrs'**
  String get hours_abbr;

  /// Abbreviated label for single minute with a leading space
  ///
  /// In en, this message translates to:
  /// **' min'**
  String get min_abbr;

  /// Abbreviated label for minutes with a leading space
  ///
  /// In en, this message translates to:
  /// **' mins'**
  String get minutes_abbr;

  /// Abbreviated label for single second with a leading space
  ///
  /// In en, this message translates to:
  /// **' sec'**
  String get sec_abbr;

  /// Abbreviated label for seconds with a leading space
  ///
  /// In en, this message translates to:
  /// **' secs'**
  String get seconds_abbr;

  /// Label for zero minute preset duration
  ///
  /// In en, this message translates to:
  /// **'0 min'**
  String get zero_min;

  /// Title for the world clock screen
  ///
  /// In en, this message translates to:
  /// **'World Clock'**
  String get world_clock;

  /// Message displayed when there are no world clocks added
  ///
  /// In en, this message translates to:
  /// **'No world clocks added yet'**
  String get no_world_clocks;

  /// Hint on how to add world clocks
  ///
  /// In en, this message translates to:
  /// **'Tap + to add cities around the world.'**
  String get tap_to_add_cities;

  /// Label indicating today
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Label indicating tomorrow
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// Label indicating yesterday
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// Message displayed when no cities match the search query
  ///
  /// In en, this message translates to:
  /// **'No cities found'**
  String get no_cities_found;

  /// Hint text for the search city field
  ///
  /// In en, this message translates to:
  /// **'Search country/ region'**
  String get search_country_region;

  /// Confirmation title when deleting an alarm
  ///
  /// In en, this message translates to:
  /// **'Delete alarm?'**
  String get delete_alarm_question;

  /// Uppercase cancel button text
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get cancel_uppercase;

  /// Label for the alarm name row
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get alarm_label;

  /// Shown for an alarm without a label, and as the hint of the label field
  ///
  /// In en, this message translates to:
  /// **'Enter label'**
  String get enter_label;

  /// Shown in the alarm editor when another alarm has the same time and repeat days; saving is disabled
  ///
  /// In en, this message translates to:
  /// **'An alarm already exists for this time'**
  String get alarm_already_exists;

  /// Title of the bottom sheet for entering an alarm label
  ///
  /// In en, this message translates to:
  /// **'Edit label'**
  String get edit_label;

  /// Error when an alarm label is too long
  ///
  /// In en, this message translates to:
  /// **'Label can be at most {max} characters'**
  String alarm_label_limit(int max);

  /// Label for the alarm snooze duration row
  ///
  /// In en, this message translates to:
  /// **'Snooze duration'**
  String get snooze_duration;

  /// A duration in minutes, e.g. 10 min
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String minutes_value(int minutes);

  /// Snackbar after saving an alarm, e.g. Alarm set for 3 days and 5 minutes from now
  ///
  /// In en, this message translates to:
  /// **'Alarm set for {duration} from now'**
  String alarm_set_for(String duration);

  /// Snackbar after saving an alarm that rings within a minute
  ///
  /// In en, this message translates to:
  /// **'Alarm set for less than a minute from now'**
  String get alarm_set_less_than_minute;

  /// Number of days in a duration
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String duration_days(int count);

  /// Number of hours in a duration
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour} other{{count} hours}}'**
  String duration_hours(int count);

  /// Number of minutes in a duration
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute} other{{count} minutes}}'**
  String duration_minutes(int count);

  /// Two items joined, e.g. 3 days and 5 minutes
  ///
  /// In en, this message translates to:
  /// **'{first} and {last}'**
  String list_two(String first, String last);

  /// Three items joined, e.g. 1 day, 2 hours and 5 minutes
  ///
  /// In en, this message translates to:
  /// **'{first}, {second} and {last}'**
  String list_three(String first, String second, String last);

  /// Reason in an error message when mxclockd can't be reached
  ///
  /// In en, this message translates to:
  /// **'clock service isn\'t running'**
  String get clock_service_unavailable;

  /// Reason in an error message when mxclockd answers in a format this app version doesn't know
  ///
  /// In en, this message translates to:
  /// **'clock service version doesn\'t match the app'**
  String get clock_service_mismatch;

  /// Snackbar when saving an alarm failed
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save alarm: {reason}'**
  String alarm_save_failed(String reason);

  /// Snackbar when switching an alarm on or off failed
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t change alarm: {reason}'**
  String alarm_toggle_failed(String reason);

  /// Snackbar when deleting an alarm failed
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete alarm: {reason}'**
  String alarm_delete_failed(String reason);

  /// Snackbar when starting or resuming a timer failed
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start timer: {reason}'**
  String timer_start_failed(String reason);

  /// Snackbar when pausing a timer failed
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t pause timer: {reason}'**
  String timer_pause_failed(String reason);

  /// Snackbar when cancelling a timer or deleting its preset failed
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t cancel timer: {reason}'**
  String timer_cancel_failed(String reason);

  /// Alarm list title when mxclockd can't be reached
  ///
  /// In en, this message translates to:
  /// **'Clock service isn\'t running'**
  String get alarms_unavailable_title;

  /// Alarm list text when mxclockd can't be reached
  ///
  /// In en, this message translates to:
  /// **'Alarms can\'t be shown or changed until it starts.'**
  String get alarms_unavailable_body;

  /// Alarm list title when mxclockd refused to list alarms
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load alarms'**
  String get alarms_load_failed_title;

  /// Button to try loading again
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;
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
