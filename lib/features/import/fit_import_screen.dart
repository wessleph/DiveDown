import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/import/file_import.dart';
import '../../domain/import/import_service.dart';
import '../../domain/import/imported_dive.dart';
import '../../l10n/app_localizations.dart';
import 'import_preview.dart';
import 'import_screen.dart';

/// Reads the picked or shared FIT file and shows its preview
/// (ui-spec §5.8, §5.9).
class FitImportScreen extends ConsumerStatefulWidget {
  const FitImportScreen({super.key});

  static const path = '/import/fit';

  /// Shorter loads show nothing, so nothing flickers (ui-spec §4).
  static const quietLoad = Duration(milliseconds: 300);

  @override
  ConsumerState<FitImportScreen> createState() => _FitImportScreenState();
}

class _FitImportScreenState extends ConsumerState<FitImportScreen> {
  String _name = '';
  bool _reading = false;
  Timer? _slow;
  FileImportFailure? _failure;
  List<ImportedDive>? _dives;
  List<ImportResult> _checks = const [];

  /// Counts files, so a late result of an earlier one is dropped.
  int _run = 0;

  @override
  void initState() {
    super.initState();
    _start(ref.read(pendingImportFileProvider));
  }

  @override
  void dispose() {
    _slow?.cancel();
    super.dispose();
  }

  Future<void> _start(PickResult? file) async {
    final run = ++_run;
    _slow?.cancel();
    switch (file) {
      case null:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go(ImportScreen.path);
        });
      case PickFailed(:final displayName, :final reason):
        setState(() {
          _name = displayName;
          _failure = reason;
          _dives = null;
          _reading = false;
        });
      case Picked(file: final picked):
        setState(() {
          _name = picked.displayName;
          _failure = null;
          _dives = null;
          _reading = false;
        });
        _slow = Timer(FitImportScreen.quietLoad, () {
          if (mounted && run == _run) setState(() => _reading = true);
        });
        final result = await ref
            .read(fileDiveSourceProvider)
            .parse(picked.bytes);
        final checks = switch (result) {
          FileDives(:final dives) =>
            await ref
                .read(importServiceProvider)
                .preview(
                  (await ref.read(activeDiverProvider.future))!.id!,
                  dives,
                ),
          FileFailed() => const <ImportResult>[],
        };
        _slow?.cancel();
        if (!mounted || run != _run) return;
        setState(() {
          _reading = false;
          switch (result) {
            case FileDives(:final dives):
              _dives = dives;
              _checks = checks;
            case FileFailed(:final reason):
              _failure = reason;
          }
        });
    }
  }

  /// Oldest first, so the numbers follow the dive order.
  Future<Set<String>> _save(
    Set<int> selected,
    Set<int> confirmed,
    List<ImportedDive> dives,
  ) async {
    final indices = selected.toList()
      ..sort((a, b) => dives[a].start.compareTo(dives[b].start));
    final diverId = (await ref.read(activeDiverProvider.future))!.id!;
    final results = await ref
        .read(importServiceProvider)
        .importDives(
          diverId,
          [for (final i in indices) dives[i]],
          confirmed: {
            for (final (pos, i) in indices.indexed)
              if (confirmed.contains(i)) pos,
          },
        );
    return {for (final r in results.whereType<Saved>()) r.saved.id!};
  }

  @override
  Widget build(BuildContext context) {
    // A new file shared while this screen is open.
    ref.listen(pendingImportFileProvider, (_, next) => _start(next));
    final l10n = AppLocalizations.of(context);
    final dives = _dives;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.importSourceFit)),
      body: SafeArea(
        child: _failure != null
            ? _failed(l10n, _failure!)
            : dives != null
            ? ImportPreview(
                key: ValueKey(_run),
                source: l10n.previewSourceFile(_name),
                dives: dives,
                checks: _checks,
                onSave: _save,
              )
            : _reading
            ? _message(
                icon: Icons.hourglass_empty,
                children: [
                  Text(l10n.fitReading),
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                ],
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _failed(AppLocalizations l10n, FileImportFailure failure) {
    final text = switch (failure) {
      FileImportFailure.tooLarge => l10n.fitTooLarge,
      FileImportFailure.noDive => l10n.fitNoDive,
      FileImportFailure.timeout => l10n.fitTimeout,
      FileImportFailure.notFit ||
      FileImportFailure.corrupt ||
      FileImportFailure.unreadable => l10n.fitUnreadable,
    };
    return _message(
      icon: Icons.error_outline,
      children: [
        Text(text, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(l10n.previewSourceFile(_name)),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => context.go(ImportScreen.path),
          child: Text(l10n.transferDone),
        ),
      ],
    );
  }

  Widget _message({required IconData icon, required List<Widget> children}) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }
}
