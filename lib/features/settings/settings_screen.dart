import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/dive/diver.dart';
import '../../domain/settings/app_settings.dart';
import '../../l10n/app_localizations.dart';
import '../logbook/dive_texts.dart';
import 'backup_flows.dart';
import 'diagnostics_screen.dart';
import 'equipment_edit_screen.dart';
import 'equipment_texts.dart';
import 'feedback_screen.dart';

/// Einstellungen (ui-spec §5.11): one diver per app, devices, appearance
/// and „Über DiveDown“. Backup (T11) and diagnostic logs (T10) follow.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const path = '/settings';

  static final privacyUrl = Uri.parse(
    'https://wessleph.github.io/DiveDown/datenschutz/',
  );
  static final sourceUrl = Uri.parse('https://github.com/wessleph/DiveDown');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final diver = ref.watch(activeDiverProvider).value;
    final open = ref.watch(urlOpenerProvider);
    final info = ref.watch(appInfoProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.navSettings,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _Section(l10n.settingsSectionDiver),
          if (diver != null) _DiverGroup(diver: diver),
          _Section(l10n.settingsSectionEquipment),
          const _EquipmentGroup(),
          _Section(l10n.settingsSectionDevices),
          const _Devices(),
          _Section(l10n.settingsSectionData),
          _Group(
            children: [
              ListTile(
                leading: const Icon(Icons.save_alt),
                title: Text(l10n.backupEntry),
                onTap: () => showCreateBackup(context, ref),
              ),
              ListTile(
                leading: const Icon(Icons.restore),
                title: Text(l10n.restoreEntry),
                onTap: () => runRestore(context, ref),
              ),
            ],
          ),
          _Section(l10n.settingsSectionHelp),
          _Group(
            children: [
              ListTile(
                leading: const Icon(Icons.report_outlined),
                title: Text(l10n.feedbackBugEntry),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(FeedbackScreen.bugPath),
              ),
              ListTile(
                leading: const Icon(Icons.lightbulb_outline),
                title: Text(l10n.feedbackIdeaEntry),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(FeedbackScreen.ideaPath),
              ),
              ListTile(
                leading: const Icon(Icons.bug_report_outlined),
                title: Text(l10n.diagnosticsTitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(DiagnosticsScreen.path),
              ),
            ],
          ),
          _Section(l10n.settingsSectionAppearance),
          const _Appearance(),
          _Section(l10n.settingsSectionAbout),
          _Group(
            children: [
              if (info != null) ...[
                ListTile(
                  title: Text(l10n.settingsVersion(info.version, info.build)),
                ),
                ListTile(title: Text(l10n.settingsLibdc(info.libdivecomputer))),
              ],
              ListTile(title: Text(l10n.settingsLicence)),
              ListTile(
                title: Text(l10n.settingsLicences),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: l10n.appTitle,
                ),
              ),
              ListTile(
                title: Text(l10n.settingsPrivacy),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => open(privacyUrl),
              ),
              ListTile(
                title: Text(l10n.settingsSource),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => open(sourceUrl),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small upper-case section title (Riff, ui-spec §1).
class _Section extends StatelessWidget {
  const _Section(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
        child: Text(
          text,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: theme.extension<DiveColors>()!.onSurfaceMuted,
          ),
        ),
      ),
    );
  }
}

/// Rows of one section on a card.
class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).extension<DiveColors>()!.outline;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (final (i, child) in children.indexed) ...[
              if (i > 0) Divider(height: 1, color: outline),
              child,
            ],
          ],
        ),
      ),
    );
  }
}

class _DiverGroup extends ConsumerWidget {
  const _DiverGroup({required this.diver});

  final Diver diver;

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _TextDialog(
        title: l10n.settingsRenameTitle,
        initial: diver.name,
        validate: (v) => v.trim().isEmpty ? l10n.welcomeNameMissing : null,
      ),
    );
    if (name == null) return;
    await ref
        .read(diverRepositoryProvider)
        .update(diver.copyWith(name: name.trim()));
    ref.invalidate(activeDiverProvider);
  }

  Future<void> _startNumber(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final text = await showDialog<String>(
      context: context,
      builder: (context) => _TextDialog(
        title: l10n.settingsStartNumber,
        initial: '${diver.firstDiveNumber}',
        number: true,
        validate: (v) {
          final n = int.tryParse(v.trim());
          return n == null || n < 1 || n > 9999
              ? l10n.settingsStartNumberInvalid
              : null;
        },
      ),
    );
    if (text == null || !context.mounted) return;
    final start = int.parse(text.trim());
    final delta = start - diver.firstDiveNumber;
    if (delta == 0) return;

    final dives = await ref.read(logbookProvider.future);
    if (dives.isNotEmpty) {
      final numbers = [for (final d in dives) d.number!]..sort();
      if (!context.mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.settingsShiftTitle),
          content: Text(
            l10n.settingsShiftBody(
              numbers.first,
              numbers.last,
              numbers.first + delta,
              numbers.last + delta,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.settingsShift),
            ),
          ],
        ),
      );
      if (ok != true) return;
      await ref.read(diveNumberingProvider).shiftNumbers(diver.id!, delta);
    }
    await ref
        .read(diverRepositoryProvider)
        .update(diver.copyWith(firstDiveNumber: start));
    ref.invalidate(activeDiverProvider);
    ref.invalidate(numbersFollowDatesProvider);
    ref.refreshDives();
  }

  Future<void> _renumber(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.settingsRenumberBody(diver.firstDiveNumber)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.settingsRenumberAction),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final count = await ref
        .read(diveNumberingProvider)
        .renumberByDate(diver.id!, start: diver.firstDiveNumber);
    ref.invalidate(numbersFollowDatesProvider);
    ref.refreshDives();
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.settingsRenumbered(count))),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final inOrder = ref.watch(numbersFollowDatesProvider).value ?? true;
    return _Group(
      children: [
        ListTile(
          title: Text(l10n.settingsName),
          subtitle: Text(diver.name),
          trailing: const Icon(Icons.edit_outlined),
          onTap: () => _rename(context, ref),
        ),
        ListTile(
          title: Text(l10n.settingsStartNumber),
          subtitle: Text(l10n.settingsStartNumberHint),
          trailing: Text(
            '${diver.firstDiveNumber}',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          onTap: () => _startNumber(context, ref),
        ),
        if (!inOrder)
          ListTile(
            title: Text(l10n.settingsRenumber),
            leading: const Icon(Icons.format_list_numbered),
            onTap: () => _renumber(context, ref),
          ),
      ],
    );
  }
}

/// One-field dialog with inline validation; returns the text or null.
class _TextDialog extends StatefulWidget {
  const _TextDialog({
    required this.title,
    required this.initial,
    required this.validate,
    this.number = false,
  });

  final String title;
  final String initial;
  final String? Function(String) validate;
  final bool number;

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final error = widget.validate(_controller.text);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: widget.number ? TextInputType.number : null,
        inputFormatters: widget.number
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        decoration: InputDecoration(errorText: error),
        onChanged: (_) => setState(() {}),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: error == null
              ? () => Navigator.pop(context, _controller.text)
              : null,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

/// Equipment list with „Ausrüstung hinzufügen“ (ui-spec §5.11, T30).
class _EquipmentGroup extends ConsumerWidget {
  const _EquipmentGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.extension<DiveColors>()!;
    final items = ref.watch(equipmentListProvider).value ?? const [];
    return _Group(
      children: [
        if (items.isEmpty) ListTile(title: Text(l10n.equipmentEmpty)),
        for (final e in items)
          ListTile(
            leading: Icon(equipmentKindIcon(e.kind), color: colors.depth),
            title: Text(e.name),
            subtitle: Row(
              children: [
                Flexible(child: Text(equipmentKindLabel(l10n, e.kind))),
                if (e.isDefault) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceTint,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      l10n.equipmentDefault,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(EquipmentEditScreen.pathFor(e.id!)),
          ),
        ListTile(
          leading: Icon(Icons.add, color: theme.colorScheme.primary),
          title: Text(
            l10n.equipmentAdd,
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          onTap: () => context.push(EquipmentEditScreen.newPath),
        ),
      ],
    );
  }
}

class _Devices extends ConsumerWidget {
  const _Devices();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final computers = ref.watch(knownComputersProvider).value ?? const [];
    if (computers.isEmpty) {
      return _Group(children: [ListTile(title: Text(l10n.settingsNoDevices))]);
    }
    return _Group(
      children: [
        for (final (:computer, :lastDive) in computers)
          ListTile(
            title: Text(computerLabel(computer)),
            subtitle: Text(
              lastDive == null
                  ? l10n.settingsNoDivesYet
                  : l10n.settingsLastDive(dateFormat.format(lastDive)),
            ),
            trailing: IconButton(
              tooltip: l10n.settingsForgetTooltip(computer.product),
              icon: const Icon(Icons.link_off),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(l10n.settingsForgetTitle(computer.product)),
                    content: Text(l10n.settingsForgetBody),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(l10n.cancel),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(l10n.settingsForget),
                      ),
                    ],
                  ),
                );
                if (ok != true) return;
                await ref
                    .read(diveComputerRepositoryProvider)
                    .forget(computer.id);
                ref.invalidate(knownComputersProvider);
              },
            ),
          ),
      ],
    );
  }
}

class _Appearance extends ConsumerWidget {
  const _Appearance();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mode = ref.watch(themeModeProvider).value ?? AppThemeMode.system;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: SegmentedButton<AppThemeMode>(
        segments: [
          ButtonSegment(
            value: AppThemeMode.system,
            label: Text(l10n.settingsThemeSystem),
          ),
          ButtonSegment(
            value: AppThemeMode.light,
            label: Text(l10n.settingsThemeLight),
          ),
          ButtonSegment(
            value: AppThemeMode.dark,
            label: Text(l10n.settingsThemeDark),
          ),
        ],
        selected: {mode},
        showSelectedIcon: false,
        onSelectionChanged: (s) =>
            ref.read(themeModeProvider.notifier).set(s.single),
      ),
    );
  }
}
