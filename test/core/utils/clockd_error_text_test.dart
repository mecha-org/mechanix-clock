import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_clock/core/services/clockd_client.dart';
import 'package:mechanix_clock/core/utils/clockd_error_text.dart';
import 'package:mechanix_clock/l10n/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();

  test('mxclockd not running', () {
    expect(
      clockdErrorReason(l10n, const ClockdUnavailable('', 'x')),
      l10n.clock_service_unavailable,
    );
  });

  test('mxclockd of another version', () {
    expect(
      clockdErrorReason(
        l10n,
        const ClockdRejected(ClockdClient.versionMismatch, 'x'),
      ),
      l10n.clock_service_mismatch,
    );
  });

  test('mxclockd refused: its own reason', () {
    expect(
      clockdErrorReason(l10n, const ClockdRejected('E', 'sound not found')),
      'sound not found',
    );
  });
}
