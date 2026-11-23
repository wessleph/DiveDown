import '../../l10n/app_localizations.dart';
import '../logbook/dive_texts.dart';

/// Up to this many days the import page says „vor N Tagen“, after that the
/// date (ui-spec §5.5, T28).
const lastUsedRelativeDays = 30;

/// Calendar days from the wall-clock date of [diveStart] to the date of
/// [now]; 0 for today and for a start in the future.
int daysSince(DateTime diveStart, DateTime now) {
  // Both as plain dates in UTC, so daylight saving does not shift a day.
  final dive = DateTime.utc(diveStart.year, diveStart.month, diveStart.day);
  final today = DateTime.utc(now.year, now.month, now.day);
  final days = today.difference(dive).inDays;
  return days < 0 ? 0 : days;
}

/// „Zuletzt: EON Core, vor 3 Tagen“ under the dive computer card
/// (ui-spec §5.5): [product] of the device with the newest dive, dated
/// [lastDive].
String lastUsedText(
  AppLocalizations l10n,
  String product,
  DateTime lastDive,
  DateTime now,
) {
  final days = daysSince(lastDive, now);
  final when = switch (days) {
    0 => l10n.lastUsedToday,
    1 => l10n.lastUsedYesterday,
    <= lastUsedRelativeDays => l10n.lastUsedDaysAgo(days),
    _ => dateFormat.format(lastDive),
  };
  return l10n.lastUsed(product, when);
}
