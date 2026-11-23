import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/equipment/equipment.dart';
import '../../l10n/app_localizations.dart';
import 'equipment_texts.dart';

/// „Ausrüstung hinzufügen“ / „Ausrüstung bearbeiten“ (ui-spec §5.11, T30).
class EquipmentEditScreen extends ConsumerStatefulWidget {
  const EquipmentEditScreen({super.key, this.equipmentId});

  static const newPath = '/settings/equipment/new';
  static String pathFor(String id) => '/settings/equipment/$id';

  /// Null for a new piece.
  final String? equipmentId;

  @override
  ConsumerState<EquipmentEditScreen> createState() =>
      _EquipmentEditScreenState();
}

class _EquipmentEditScreenState extends ConsumerState<EquipmentEditScreen> {
  final _name = TextEditingController();
  final _notes = TextEditingController();
  final _nameFocus = FocusNode();
  EquipmentKind? _kind;
  bool _isDefault = false;

  /// The stored piece when editing; set once loaded.
  Equipment? _original;
  bool _loaded = false;
  bool _submitted = false;
  bool _saving = false;
  ({EquipmentKind? kind, String name, String notes, bool isDefault})? _initial;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (widget.equipmentId case final id?) {
      final all = await ref.read(equipmentListProvider.future);
      _original = all.where((e) => e.id == id).firstOrNull;
      if (_original case final e?) {
        _kind = e.kind;
        _name.text = e.name;
        _notes.text = e.notes ?? '';
        _isDefault = e.isDefault;
      }
    }
    if (!mounted) return;
    setState(() {
      _loaded = true;
      _initial = _current;
    });
  }

  ({EquipmentKind? kind, String name, String notes, bool isDefault})
  get _current => (
    kind: _kind,
    name: _name.text,
    notes: _notes.text,
    isDefault: _isDefault,
  );

  bool get _dirty => _loaded && !_saving && _current != _initial;

  String? _nameError(AppLocalizations l10n) =>
      _submitted && _name.text.trim().isEmpty
      ? l10n.equipmentNameMissing
      : null;

  String? _kindError(AppLocalizations l10n) =>
      _submitted && _kind == null ? l10n.equipmentKindMissing : null;

  Future<void> _save() async {
    setState(() => _submitted = true);
    if (_kind == null) return;
    if (_name.text.trim().isEmpty) {
      _nameFocus.requestFocus();
      return;
    }
    setState(() => _saving = true);
    final diver = await ref.read(activeDiverProvider.future);
    final item = Equipment(
      id: _original?.id,
      diverId: _original?.diverId ?? diver!.id!,
      kind: _kind!,
      name: _name.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      isDefault: _isDefault,
    );
    await ref.read(equipmentRepositoryProvider).save(item);
    ref.invalidate(equipmentListProvider);
    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final e = _original!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.equipmentDeleteQuestion(e.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _saving = true);
    await ref.read(equipmentRepositoryProvider).delete(e.id!);
    ref.invalidate(equipmentListProvider);
    if (mounted) context.pop();
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
    if (discard == true && mounted) {
      _initial = _current;
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final editing = widget.equipmentId != null;
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(editing ? l10n.equipmentEditTitle : l10n.equipmentAdd),
          actions: [
            if (_original != null)
              PopupMenuButton<String>(
                onSelected: (_) => _delete(),
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
                ],
              ),
          ],
        ),
        bottomNavigationBar: !_loaded
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
        body: !_loaded
            ? const SizedBox.shrink()
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  DropdownButtonFormField<EquipmentKind>(
                    initialValue: _kind,
                    decoration: InputDecoration(
                      labelText: l10n.requiredField(l10n.equipmentKindField),
                      errorText: _kindError(l10n),
                    ),
                    items: [
                      for (final k in EquipmentKind.values)
                        DropdownMenuItem(
                          value: k,
                          child: Row(
                            children: [
                              Icon(equipmentKindIcon(k), size: 20),
                              const SizedBox(width: 12),
                              Text(equipmentKindLabel(l10n, k)),
                            ],
                          ),
                        ),
                    ],
                    onChanged: (k) => setState(() => _kind = k),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _name,
                    focusNode: _nameFocus,
                    maxLength: Equipment.maxNameLength,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: l10n.requiredField(l10n.equipmentNameField),
                      hintText: l10n.equipmentNameHint,
                      errorText: _nameError(l10n),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _notes,
                    minLines: 2,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: l10n.equipmentNotesField,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.equipmentDefault),
                    subtitle: Text(l10n.equipmentDefaultHint),
                    value: _isDefault,
                    onChanged: (v) => setState(() => _isDefault = v),
                  ),
                ],
              ),
      ),
    );
  }
}
