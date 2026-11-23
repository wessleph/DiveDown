// T28.1-T28.2: „Zuletzt: EON Core, vor 3 Tagen“ (ui-spec §5.5).
import 'package:divedown/features/import/last_used.dart';
import 'package:divedown/l10n/app_localizations_de.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  final l10n = AppLocalizationsDe();
  final now = DateTime(2026, 11, 23, 8, 15);

  // The app loads the German date data at start; a unit test must do it.
  setUpAll(() => initializeDateFormatting('de'));

  test('T28.1 calendar days, not hours', () {
    // Dive starts are wall-clock times stored as UTC fields.
    expect(daysSince(DateTime.utc(2026, 11, 23, 6), now), 0);
    expect(daysSince(DateTime.utc(2026, 11, 22, 23, 50), now), 1);
    expect(daysSince(DateTime.utc(2026, 11, 20, 9), now), 3);
    expect(daysSince(DateTime.utc(2026, 10, 31, 9), now), 23);
    expect(daysSince(DateTime.utc(2026, 11, 25, 9), now), 0, reason: 'clock');
  });

  test('T28.2 today, yesterday, days, then the date', () {
    String text(DateTime d) => lastUsedText(l10n, 'EON Core', d, now);

    expect(text(DateTime.utc(2026, 11, 23, 7)), 'Zuletzt: EON Core, heute');
    expect(text(DateTime.utc(2026, 11, 22, 9)), 'Zuletzt: EON Core, gestern');
    expect(
      text(DateTime.utc(2026, 11, 20, 9)),
      'Zuletzt: EON Core, vor 3 Tagen',
    );
    expect(
      text(DateTime.utc(2026, 10, 24, 9)),
      'Zuletzt: EON Core, vor 30 Tagen',
    );
    expect(text(DateTime.utc(2026, 10, 9, 9)), 'Zuletzt: EON Core, 09.10.2026');
  });
}
