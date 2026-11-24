import 'package:mechanix_clock/core/services/clockd_client.dart';
import 'package:mechanix_clock/l10n/app_localizations.dart';

/// Why a call to mxclockd failed, for the end of a message such as
/// "Couldn't save alarm: …".
String clockdErrorReason(AppLocalizations l10n, ClockdException error) =>
    switch (error) {
      ClockdUnavailable() => l10n.clock_service_unavailable,
      ClockdRejected(errorName: ClockdClient.versionMismatch) =>
        l10n.clock_service_mismatch,
      ClockdRejected(:final message) => message,
    };
