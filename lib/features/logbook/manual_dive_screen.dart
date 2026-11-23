import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/dive/dive.dart';
import '../../domain/dive/dive_repository.dart';
import '../../domain/dive/manual_dive_draft.dart';
import '../../domain/equipment/equipment.dart';
import '../../domain/sites/site_suggestions.dart';
import '../../l10n/app_localizations.dart';
import '../settings/equipment_edit_screen.dart';
import '../settings/equipment_texts.dart';
import 'dive_detail_screen.dart';
import 'dive_texts.dart';
import 'logbook_screen.dart';
import 'site_field.dart';

/// Manuell eintragen / Bearbeiten (ui-spec §5.4).
class ManualDiveScreen extends ConsumerStatefulWidget {
  const ManualDiveScreen({super.key, this.diveId});

  static const newPath = '/logbook/new';
  static String editPathFor(String diveId) => '/logbook/dive/$diveId/edit';

  /// The dive to edit; null for a new one.
  final String? diveId;

  @override
  ConsumerState<ManualDiveScreen> createState() => _ManualDiveScreenState();
}

/// Text fields of the form, in screen order (site has no validation).
const _textFields = [
  ManualDiveField.number,
  ManualDiveField.duration,
  ManualDiveField.maxDepth,
  ManualDiveField.avgDepth,
  ManualDiveField.temperature,
  ManualDiveField.tankVolume,
  ManualDiveField.startPressure,
  ManualDiveField.endPressure,
  ManualDiveField.o2,
  ManualDiveField.weight,
];

class _ManualDiveScreenState extends ConsumerState<ManualDiveScreen> {
  final _controllers = {
    for (final f in _textFields) f: TextEditingController(),
  };
  final _focus = {for (final f in _textFields) f: FocusNode()};
  final _site = TextEditingController();
  final _notes = TextEditingController();

  /// Set once loaded; null while the dive or next number is read.
  ManualDiveDraft? _initial;
  Dive? _original;
  late DateTime _start;
  WaterType? _waterType;
  int? _rating;

  /// Selected equipment (ADR 0007); null until loaded.
  Set<String>? _equipment;

  /// Pieces of the edited dive that were deleted since (shown muted).
  List<Equipment> _deletedOnDive = const [];

  /// „Zuletzt bei Elphinstone: 6 kg“ for the current site (T31.3).
  ({double weightKg, String siteName})? _lastWeight;
  int _hintRequest = 0;

  /// Catalogue link and position of the chosen site (ADR 0006); cleared as
  /// soon as the name is typed over.
  ({String? id, double? lat, double? lon}) _siteLink = _noLink;
  static const _noLink = (id: null, lat: null, lon: null);
  Map<ManualDiveField, ManualDiveError> _errors = const {};
  bool _submitted = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [..._controllers.values, _site, _notes]) {
      c.dispose();
    }
    for (final f in _focus.values) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final ManualDiveDraft draft;
    if (widget.diveId case final id?) {
      final dive = await ref.read(diveRepositoryProvider).findById(id);
      if (dive == null) return;
      _original = dive;
      draft = ManualDiveDraft.fromDive(dive);
      _deletedOnDive = [
        for (final e in await ref.read(equipmentRepositoryProvider).forDive(id))
          if (e.deleted) e,
      ];
    } else {
      final diver = await ref.read(activeDiverProvider.future);
      final next = await ref
          .read(diveRepositoryProvider)
          .nextNumber(diver!.id!);
      final now = clock.now();
      final defaults = await ref.read(equipmentListProvider.future);
      draft = ManualDiveDraft(
        number: '$next',
        start: DateTime(now.year, now.month, now.day, now.hour, now.minute),
        equipmentIds: {
          for (final e in defaults)
            if (e.isDefault) e.id!,
        },
      );
    }
    if (!mounted) return;
    setState(() {
      _initial = draft;
      _fill(draft);
    });
    _refreshWeightHint();
  }

  /// Looks up the lead of the last dive at the current site.
  Future<void> _refreshWeightHint() async {
    final request = ++_hintRequest;
    final diver =
        _original?.diverId ?? (await ref.read(activeDiverProvider.future))?.id;
    final site = _site.text.trim();
    final last = diver == null || (site.isEmpty && _siteLink.id == null)
        ? null
        : await ref
              .read(diveRepositoryProvider)
              .lastWeightAt(
                diver,
                siteName: site,
                siteCatalogueId: _siteLink.id,
                excludeDiveId: _original?.id,
              );
    if (!mounted || request != _hintRequest) return;
    setState(() => _lastWeight = last);
  }

  void _fill(ManualDiveDraft d) {
    final texts = {
      ManualDiveField.number: d.number,
      ManualDiveField.duration: d.duration,
      ManualDiveField.maxDepth: d.maxDepth,
      ManualDiveField.avgDepth: d.avgDepth,
      ManualDiveField.temperature: d.temperature,
      ManualDiveField.tankVolume: d.tankVolume,
      ManualDiveField.startPressure: d.startPressure,
      ManualDiveField.endPressure: d.endPressure,
      ManualDiveField.o2: d.o2,
      ManualDiveField.weight: d.weight,
    };
    for (final MapEntry(:key, :value) in texts.entries) {
      _controllers[key]!.text = value;
    }
    _site.text = d.siteName;
    _siteLink = (id: d.siteCatalogueId, lat: d.siteLat, lon: d.siteLon);
    _notes.text = d.notes;
    _start = d.start;
    _waterType = d.waterType;
    _rating = d.rating;
    _equipment = d.equipmentIds == null ? null : {...d.equipmentIds!};
  }

  ManualDiveDraft get _draft {
    String t(ManualDiveField f) => _controllers[f]!.text;
    return ManualDiveDraft(
      number: t(ManualDiveField.number),
      siteName: _site.text,
      siteCatalogueId: _siteLink.id,
      siteLat: _siteLink.lat,
      siteLon: _siteLink.lon,
      start: _start,
      duration: t(ManualDiveField.duration),
      maxDepth: t(ManualDiveField.maxDepth),
      avgDepth: t(ManualDiveField.avgDepth),
      temperature: t(ManualDiveField.temperature),
      tankVolume: t(ManualDiveField.tankVolume),
      startPressure: t(ManualDiveField.startPressure),
      endPressure: t(ManualDiveField.endPressure),
      o2: t(ManualDiveField.o2),
      weight: t(ManualDiveField.weight),
      equipmentIds: _equipment == null ? null : {..._equipment!},
      waterType: _waterType,
      notes: _notes.text,
      rating: _rating,
    );
  }

  bool get _dirty {
    final a = _initial;
    if (a == null) return false;
    final b = _draft;
    return a.number != b.number ||
        a.siteName != b.siteName ||
        a.siteCatalogueId != b.siteCatalogueId ||
        a.start != b.start ||
        a.duration != b.duration ||
        a.maxDepth != b.maxDepth ||
        a.avgDepth != b.avgDepth ||
        a.temperature != b.temperature ||
        a.tankVolume != b.tankVolume ||
        a.startPressure != b.startPressure ||
        a.endPressure != b.endPressure ||
        a.o2 != b.o2 ||
        a.weight != b.weight ||
        !_sameSet(a.equipmentIds, b.equipmentIds) ||
        a.waterType != b.waterType ||
        a.notes != b.notes ||
        a.rating != b.rating;
  }

  static bool _sameSet(Set<String>? a, Set<String>? b) =>
      (a ?? const {}).length == (b ?? const {}).length &&
      (a ?? const {}).containsAll(b ?? const {});

  void _siteChosen(SiteSuggestion s) {
    _siteLink = switch (s) {
      OwnSiteSuggestion(:final site) => (
        id: site.catalogueId,
        lat: site.lat,
        lon: site.lon,
      ),
      CatalogueSiteSuggestion(:final site) => (
        id: site.id,
        lat: site.lat,
        lon: site.lon,
      ),
      NewSiteSuggestion() => _noLink,
    };
    _changed();
    _refreshWeightHint();
  }

  void _siteTyped(String _) {
    _siteLink = _noLink;
    _changed();
    _refreshWeightHint();
  }

  /// Rebuilds for the dirty state and, after the first save, inline errors.
  void _changed() => setState(() {
    if (_submitted) _errors = _draft.validate();
  });

  Future<void> _save() async {
    final errors = _draft.validate();
    setState(() {
      _submitted = true;
      _errors = errors;
    });
    if (errors.isNotEmpty) {
      _focus[errors.keys.first]?.requestFocus();
      return;
    }

    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final diverId =
        _original?.diverId ?? (await ref.read(activeDiverProvider.future))!.id!;
    final result = await ref
        .read(diveRepositoryProvider)
        .save(_draft.toDive(diverId: diverId, original: _original));
    ref.refreshDives(diveId: result.dive.id);
    if (!mounted) return;

    _initial = _draft; // nothing left to discard
    if (result.warnings.contains(DiveWarning.duplicateNumber)) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.duplicateNumber(result.dive.number!))),
      );
    }
    context.go(
      _original == null
          ? LogbookScreen.path
          : DiveDetailScreen.pathFor(result.dive.id!),
    );
  }

  Future<void> _confirmLeave() async {
    final l10n = AppLocalizations.of(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.discardTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.keepEditing),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.discard),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  Future<void> _pickDate() async {
    final now = clock.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _start.isAfter(now) ? now : _start,
      firstDate: DateTime(1950),
      lastDate: now,
    );
    if (picked == null) return;
    _start = _withDate(_start, picked);
    _changed();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _start.hour, minute: _start.minute),
    );
    if (picked == null) return;
    _start = _withTime(_start, picked.hour, picked.minute);
    _changed();
  }

  /// Keeps the UTC flag of [start], so edited wall-clock times stay put.
  static DateTime _withDate(DateTime start, DateTime d) => start.isUtc
      ? DateTime.utc(d.year, d.month, d.day, start.hour, start.minute)
      : DateTime(d.year, d.month, d.day, start.hour, start.minute);

  static DateTime _withTime(DateTime start, int hour, int minute) => start.isUtc
      ? DateTime.utc(start.year, start.month, start.day, hour, minute)
      : DateTime(start.year, start.month, start.day, hour, minute);

  String _errorText(AppLocalizations l10n, ManualDiveError e) => switch (e) {
    ManualDiveError.required => l10n.errorRequired,
    ManualDiveError.notANumber => l10n.errorNotANumber,
    ManualDiveError.numberInvalid => l10n.errorNumberInvalid,
    ManualDiveError.dateInFuture => l10n.errorDateInFuture,
    ManualDiveError.durationOutOfRange => l10n.errorDuration,
    ManualDiveError.depthOutOfRange => l10n.errorDepth,
    ManualDiveError.avgDepthAboveMax => l10n.errorAvgDepthAboveMax,
    ManualDiveError.temperatureOutOfRange => l10n.errorTemperature,
    ManualDiveError.volumeOutOfRange => l10n.errorVolume,
    ManualDiveError.pressureOutOfRange => l10n.errorPressure,
    ManualDiveError.endPressureNotBelowStart => l10n.errorEndPressure,
    ManualDiveError.o2OutOfRange => l10n.errorO2,
    ManualDiveError.weightOutOfRange => l10n.errorWeight,
  };

  /// „Zuletzt bei Elphinstone: 6 kg · Übernehmen“, unless the field already
  /// has that value (ui-spec §5.4).
  Widget? _weightHint(AppLocalizations l10n) {
    final last = _lastWeight;
    if (last == null) return null;
    final typed = double.tryParse(
      _controllers[ManualDiveField.weight]!.text.trim().replaceAll(',', '.'),
    );
    if (typed == last.weightKg) return null;
    final colors = Theme.of(context).extension<DiveColors>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.history, size: 18, color: colors.onSurfaceMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              l10n.weightLastAt(last.siteName, formatKg(last.weightKg)),
              style: TextStyle(color: colors.onSurfaceMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              _controllers[ManualDiveField.weight]!.text = formatKg(
                last.weightKg,
              );
              _changed();
            },
            child: Text(l10n.weightApply),
          ),
        ],
      ),
    );
  }

  /// Filter chips for the equipment (ui-spec §5.4, T31.4).
  Widget _equipmentChips(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final colors = theme.extension<DiveColors>()!;
    final live = ref.watch(equipmentListProvider).value ?? const [];
    final items = [
      ...live,
      for (final e in _deletedOnDive)
        if (_equipment?.contains(e.id) ?? false) e,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.fieldEquipment, style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        if (items.isEmpty)
          Row(
            children: [
              Expanded(child: Text(l10n.equipmentNoneInForm)),
              TextButton(
                onPressed: () => context.push(EquipmentEditScreen.newPath),
                child: Text(l10n.equipmentCreateLink),
              ),
            ],
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final e in items)
                FilterChip(
                  avatar: _equipment?.contains(e.id) ?? false
                      ? null
                      : Icon(equipmentKindIcon(e.kind), size: 18),
                  label: Text(
                    e.name,
                    style: e.deleted
                        ? TextStyle(color: colors.onSurfaceMuted)
                        : null,
                  ),
                  selected: _equipment?.contains(e.id) ?? false,
                  onSelected: (on) {
                    final next = {...?_equipment};
                    on ? next.add(e.id!) : next.remove(e.id);
                    _equipment = next;
                    _changed();
                  },
                ),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final loaded = _initial != null;

    Widget field(
      ManualDiveField f,
      String label, {
      bool required = false,
      bool decimal = false,
    }) {
      final error = _errors[f];
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: _controllers[f],
          focusNode: _focus[f],
          keyboardType: decimal
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.number,
          textInputAction: TextInputAction.next,
          onChanged: (_) => _changed(),
          decoration: InputDecoration(
            labelText: required ? l10n.requiredField(label) : label,
            errorText: error == null ? null : _errorText(l10n, error),
            errorMaxLines: 3,
          ),
        ),
      );
    }

    Widget pickerField(
      String label,
      String value,
      VoidCallback onTap, {
      String? error,
    }) {
      return InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: l10n.requiredField(label),
            errorText: error,
            errorMaxLines: 3,
          ),
          child: Text(value),
        ),
      );
    }

    final startError = _errors[ManualDiveField.start];

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.diveId == null ? l10n.formNewTitle : l10n.formEditTitle,
          ),
        ),
        bottomNavigationBar: !loaded
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                    ),
                    onPressed: _saving ? null : _save,
                    child: Text(l10n.save),
                  ),
                ),
              ),
        body: !loaded
            ? const SizedBox.shrink()
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  field(ManualDiveField.number, l10n.fieldNumber),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SiteField(
                      controller: _site,
                      onChosen: _siteChosen,
                      onTyped: _siteTyped,
                    ),
                  ),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 160,
                        child: pickerField(
                          l10n.fieldDate,
                          dateFormat.format(_start),
                          _pickDate,
                          error: startError == null
                              ? null
                              : _errorText(l10n, startError),
                        ),
                      ),
                      SizedBox(
                        width: 160,
                        child: pickerField(
                          l10n.fieldStartTime,
                          timeFormat.format(_start),
                          _pickTime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  field(
                    ManualDiveField.duration,
                    l10n.fieldDuration,
                    required: true,
                  ),
                  field(
                    ManualDiveField.maxDepth,
                    l10n.fieldMaxDepth,
                    required: true,
                    decimal: true,
                  ),
                  field(
                    ManualDiveField.avgDepth,
                    l10n.fieldAvgDepth,
                    decimal: true,
                  ),
                  field(
                    ManualDiveField.temperature,
                    l10n.fieldTemperature,
                    decimal: true,
                  ),
                  field(
                    ManualDiveField.tankVolume,
                    l10n.fieldTankVolume,
                    decimal: true,
                  ),
                  field(ManualDiveField.startPressure, l10n.fieldStartPressure),
                  field(ManualDiveField.endPressure, l10n.fieldEndPressure),
                  field(ManualDiveField.o2, l10n.fieldO2),
                  field(
                    ManualDiveField.weight,
                    l10n.fieldWeight,
                    decimal: true,
                  ),
                  ?_weightHint(l10n),
                  _equipmentChips(l10n),
                  const SizedBox(height: 12),
                  Text(
                    l10n.fieldWaterType,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  SegmentedButton<WaterType>(
                    emptySelectionAllowed: true,
                    showSelectedIcon: false,
                    segments: [
                      for (final w in WaterType.values)
                        ButtonSegment(
                          value: w,
                          label: Text(waterTypeLabel(l10n, w)),
                        ),
                    ],
                    selected: {?_waterType},
                    onSelectionChanged: (s) {
                      _waterType = s.firstOrNull;
                      _changed();
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notes,
                    minLines: 3,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => _changed(),
                    decoration: InputDecoration(labelText: l10n.fieldNotes),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.fieldRating,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Wrap(
                    children: [
                      for (var i = 1; i <= 5; i++)
                        IconButton(
                          tooltip: l10n.ratingStars(i),
                          isSelected: (_rating ?? 0) >= i,
                          icon: const Icon(Icons.star_border),
                          selectedIcon: const Icon(Icons.star),
                          onPressed: () {
                            // Tapping the current rating again clears it.
                            _rating = _rating == i ? null : i;
                            _changed();
                          },
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
