import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../data/backup/logbook_backup.dart';
import '../../domain/import/file_import.dart';
import '../../l10n/app_localizations.dart';
import '../logbook/dive_texts.dart';

/// „Logbuch sichern“ (ui-spec §5.12): hint and warning, then the share
/// dialog with the backup file.
Future<void> showCreateBackup(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      final warning = theme.extension<DiveColors>()!.warning;
      return AlertDialog(
        title: Text(l10n.backupEntry),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.backupInfo),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.backupWarning,
                    style: TextStyle(color: warning),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.backupCreate),
          ),
        ],
      );
    },
  );
  if (ok != true || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  try {
    final file = await ref.read(backupActionsProvider).create();
    await ref.read(shareFileProvider)(file.name, file.bytes);
    await ref.read(appSettingsProvider).setLastBackupAt(clock.now().toUtc());
    ref.invalidate(backupReminderProvider);
    messenger.showSnackBar(SnackBar(content: Text(l10n.backupCreated)));
  } on Exception {
    messenger.showSnackBar(SnackBar(content: Text(l10n.backupFailed)));
  }
}

/// „Logbuch wiederherstellen“ (ui-spec §5.12): choose, check, confirm,
/// replace, then reopen the app.
Future<void> runRestore(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final picked = await ref.read(backupFilePickerProvider).pick();
  if (picked == null || !context.mounted) return;
  final actions = ref.read(backupActionsProvider);

  Future<void> tell(String text) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      content: Text(text),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.ok),
        ),
      ],
    ),
  );

  String problemText(BackupProblem problem) => switch (problem) {
    BackupProblem.tooLarge => l10n.restoreTooLarge,
    BackupProblem.invalid => l10n.restoreInvalid,
    BackupProblem.corrupt => l10n.restoreCorrupt,
    BackupProblem.newerVersion => l10n.restoreNewer,
  };

  final ImportFile file;
  switch (picked) {
    case Picked(file: final f):
      file = f;
    case PickFailed(reason: FileImportFailure.tooLarge):
      await tell(l10n.restoreTooLarge);
      return;
    case PickFailed():
      await tell(l10n.restoreInvalid);
      return;
  }
  if (!context.mounted) return;

  final check = actions.inspect(file.bytes);
  if (check case BackupRejected(:final problem)) {
    await tell(problemText(problem));
    return;
  }
  final manifest = (check as BackupReadable).manifest;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.restoreEntry),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.restoreSummary(
              dateFormat.format(manifest.createdAt.toLocal()),
              manifest.diveCount,
            ),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(l10n.restoreReplaceInfo),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.restoreAction),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;

  final result = await actions.restore(file.bytes);
  if (!context.mounted) return;
  switch (result) {
    case Restored():
      final restart = ref.read(restartAppProvider);
      await tell(l10n.restoreDone);
      // The database was replaced: open it again with fresh providers.
      restart();
    case RestoreRejected(:final problem):
      await tell(problemText(problem));
    case RestoreFailed():
      await tell(l10n.restoreFailed);
  }
}
