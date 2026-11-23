import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/dive/dive.dart';
import '../../domain/import/import_service.dart';
import '../../domain/import/imported_dive.dart';
import '../../domain/sites/site_suggestions.dart';
import '../../domain/units/unit_formatter.dart';
import '../../l10n/app_localizations.dart';
import '../logbook/dive_texts.dart';
import '../logbook/logbook_screen.dart';
import '../logbook/site_field.dart';

/// Saves the dives at [selected] (indices into [dives], the previewed dives
/// with the sites set in the preview), those in [confirmed] although they
/// need confirmation. Returns how many were saved.
typedef SaveSelected = Future<int> Function(
  Set<int> selected,
  Set<int> confirmed,
  List<ImportedDive> dives,
);

/// The import preview for every source (ui-spec §5.9): duplicates marked,
/// numbers the dives will get, save and back to the logbook.
class ImportPreview extends ConsumerStatefulWidget {
  const ImportPreview({
    super.key,
    required this.source,
    this.notes = const [],
    required this.dives,
    required this.checks,
    required this.onSave,
  });

  /// „Vom Tauchcomputer: …“ or „Aus Datei: …“ (security.md A2).
  final String source;

  /// Extra lines under the header, e.g. „Übertragung abgebrochen.“
  final List<String> notes;
  final List<ImportedDive> dives;

  /// One per dive, from [ImportService.preview].
  final List<ImportResult> checks;
  final SaveSelected onSave;

  @override
  ConsumerState<ImportPreview> createState() => _ImportPreviewState();
}

class _ImportPreviewState extends ConsumerState<ImportPreview> {
  static const _units = UnitFormatter.metric();
  static final _shortDate = DateFormat('dd.MM.', 'de');

  late final Set<int> _selected = {
    for (final (i, c) in widget.checks.indexed)
      if (c is Saved) i,
  };
  final _similar = <int, Dive>{};

  /// The previewed dives with the sites set here (T25).
  late final List<ImportedDive> _dives = [...widget.dives];
  int _firstNumber = 1;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final dives = ref.read(diveRepositoryProvider);
    final diverId = (await ref.read(activeDiverProvider.future))!.id!;
    final firstNumber = await dives.nextNumber(diverId);
    final similar = <int, Dive>{};
    for (final (i, check) in widget.checks.indexed) {
      if (check is NeedsConfirmation) {
        final other = await dives.findById(check.possibleMatchId);
        if (other != null) similar[i] = other;
      }
    }
    if (!mounted) return;
    setState(() {
      _firstNumber = firstNumber;
      _similar.addAll(similar);
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    final saved = await widget.onSave(
      {..._selected},
      {
        for (final i in _selected)
          if (widget.checks[i] is NeedsConfirmation) i,
      },
      [..._dives],
    );
    ref.refreshDives();
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(l10n.importedSnack(saved))));
    context.go(LogbookScreen.path);
  }

  /// Numbers the selected dives get, in the order of their start.
  Map<int, int> _numbers() {
    final order = _selected.toList()
      ..sort((a, b) => _dives[a].start.compareTo(_dives[b].start));
    return {for (final (rank, i) in order.indexed) i: _firstNumber + rank};
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final numbers = _numbers();
    return PopScope(
      canPop: !_saving,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.source),
                      for (final note in widget.notes) ...[
                        const SizedBox(height: 8),
                        Text(note),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                for (final (i, dive) in _dives.indexed)
                  _row(l10n, theme, i, dive, numbers[i]),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: _selected.isEmpty || _saving
                          ? null
                          : _chooseSite,
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: Text(l10n.previewSetSite),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _button(l10n),
        ],
      ),
    );
  }

  Widget _row(
    AppLocalizations l10n,
    ThemeData theme,
    int i,
    ImportedDive dive,
    int? number,
  ) {
    final colors = theme.extension<DiveColors>()!;
    final check = widget.checks[i];
    final selectable = check is Saved || check is NeedsConfirmation;
    final similar = _similar[i];
    final note = switch (check) {
      NeedsConfirmation(reason: ConfirmReason.sameIdDifferentContent) =>
        l10n.previewSameIdOtherData,
      NeedsConfirmation() when similar != null => l10n.previewSimilar(
        _shortDate.format(similar.start),
        _units.depth(similar.maxDepthM),
        _units.duration(similar.durationS),
      ),
      NeedsConfirmation() => l10n.previewSameIdOtherData,
      SkippedDuplicate() => l10n.previewAlreadyThere,
      Rejected() || Failed() => l10n.previewRejected,
      Saved() => null,
    };

    void toggle(bool? on) =>
        setState(() => on == true ? _selected.add(i) : _selected.remove(i));

    return InkWell(
      onTap: selectable ? () => toggle(!_selected.contains(i)) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _selected.contains(i),
              onChanged: selectable ? toggle : null,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      [
                        if (number != null) l10n.diveNumber(number),
                        '${dateFormat.format(dive.start)} · '
                            '${timeFormat.format(dive.start)}',
                      ].join('  '),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: selectable ? null : colors.onSurfaceMuted,
                      ),
                    ),
                    Text(
                      '${_units.depth(dive.maxDepthM)} · '
                      '${_units.duration(dive.durationS)}',
                      style: TextStyle(color: colors.onSurfaceMuted),
                    ),
                    if (dive.siteName case final site?)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Icon(
                              Icons.place_outlined,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                site,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (note != null)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (check is NeedsConfirmation) ...[
                            Icon(
                              Icons.warning_amber_outlined,
                              size: 18,
                              color: colors.warning,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Expanded(child: Text(note)),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// „Tauchplatz für Ausgewählte setzen“ (ui-spec §5.9, T25).
  Future<void> _chooseSite() async {
    final targets = {..._selected};
    final result = await showModalBottomSheet<({ChosenSite? site})>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _SiteSheet(
        count: targets.length,
        canRemove: targets.any((i) => _dives[i].siteName != null),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      for (final i in targets) {
        _dives[i] = _dives[i].withSite(result.site);
      }
    });
  }

  Widget _button(AppLocalizations l10n) {
    final count = _selected.length;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 56,
          width: double.infinity,
          child: FilledButton(
            onPressed: count == 0 || _saving ? null : _save,
            child: _saving
                ? const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : Text(
                    count == 0
                        ? l10n.previewNothing
                        : l10n.previewImport(count),
                  ),
          ),
        ),
      ),
    );
  }
}

/// The sheet behind „Tauchplatz für Ausgewählte setzen“. Pops with the
/// chosen site, with `site: null` for „Tauchplatz entfernen“, or nothing.
class _SiteSheet extends StatefulWidget {
  const _SiteSheet({required this.count, required this.canRemove});

  final int count;
  final bool canRemove;

  @override
  State<_SiteSheet> createState() => _SiteSheetState();
}

class _SiteSheetState extends State<_SiteSheet> {
  final _name = TextEditingController();

  /// A tapped suggestion, as long as the text was not changed afterwards.
  ChosenSite? _chosen;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  ChosenSite? get _site => _chosen ?? ChosenSite.typed(_name.text);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final site = _site;
    // Above the keyboard and the system navigation bar.
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, bottom: 16 + bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.previewSiteTitle(widget.count),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              SiteField(
                controller: _name,
                onChosen: (s) =>
                    setState(() => _chosen = ChosenSite.fromSuggestion(s)),
                onTyped: (_) => setState(() => _chosen = null),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: site == null
                      ? null
                      : () => Navigator.pop(context, (site: site)),
                  child: Text(l10n.previewSiteApply),
                ),
              ),
              if (widget.canRemove) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: TextButton(
                    onPressed: () =>
                        Navigator.pop(context, (site: null as ChosenSite?)),
                    child: Text(l10n.previewSiteRemove),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
