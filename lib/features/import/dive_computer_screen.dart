import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/import/bluetooth_access.dart';
import '../../domain/import/dive_computer_import.dart';
import '../../domain/import/dive_computer_source.dart';
import '../../domain/import/import_service.dart';
import '../../domain/import/imported_dive.dart';
import '../../l10n/app_localizations.dart';
import '../settings/diagnostics_screen.dart';
import 'import_preview.dart';
import 'import_screen.dart';

/// Search, transfer and preview for the BLE import (ui-spec §5.6, §5.7, §5.9).
class DiveComputerScreen extends ConsumerStatefulWidget {
  const DiveComputerScreen({super.key});

  static const path = '/import/divecomputer';

  /// The scan stops by itself after this (ui-spec §5.6).
  static const scanTimeout = Duration(seconds: 30);

  /// Time to type the code the computer shows (ui-spec §5.6).
  static const pinTimeout = Duration(seconds: 60);

  @override
  ConsumerState<DiveComputerScreen> createState() => _DiveComputerScreenState();
}

enum _Phase {
  checking,
  blocked,
  scanning,
  scanEnded,
  transferring,
  ended,
  preview,
}

class _Found {
  _Found(this.computer);

  final DiscoveredComputer computer;
  bool known = false;
}

class _DiveComputerScreenState extends ConsumerState<DiveComputerScreen> {
  late final AppLifecycleListener _lifecycle;
  _Phase _phase = _Phase.checking;
  BluetoothReadiness _readiness = BluetoothReadiness.ready;

  final _found = <_Found>[];
  StreamSubscription<DiscoveredComputer>? _scan;
  Timer? _scanTimer;

  DiscoveredComputer? _computer;
  int _received = 0;
  TransferProgress? _progress;
  bool _pinTimedOut = false;
  DownloadResult? _result;

  // Preview
  List<ImportResult> _checks = const [];
  bool _asNewDevice = false;

  // Read once: `ref` is not usable any more in dispose (Riverpod 3).
  late final DiveComputerSource _source = ref.read(diveComputerSourceProvider);
  late final DiveComputerImport _import = ref.read(diveComputerImportProvider);
  late final ScreenAwake _awake = ref.read(screenAwakeProvider);

  @override
  void initState() {
    super.initState();
    _source;
    _import;
    _awake;
    // Back from the system settings or the Bluetooth dialog: look again.
    _lifecycle = AppLifecycleListener(
      onResume: () {
        if (_phase == _Phase.blocked) _check();
      },
    );
    _check();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _scanTimer?.cancel();
    _scan?.cancel();
    if (_phase == _Phase.scanning) _source.stopDiscovery();
    if (_phase == _Phase.transferring) {
      _import.cancel();
      _awake.keepOn(false);
    }
    super.dispose();
  }

  BluetoothAccess get _access => ref.read(bluetoothAccessProvider);

  Future<void> _check() async {
    final readiness = await _access.check();
    if (!mounted) return;
    _onReadiness(readiness);
  }

  void _onReadiness(BluetoothReadiness readiness) {
    if (readiness == BluetoothReadiness.ready) {
      _startScan();
    } else {
      setState(() {
        _readiness = readiness;
        _phase = _Phase.blocked;
      });
    }
  }

  Future<void> _requestPermission() async {
    final readiness = await _access.requestPermission();
    if (mounted) _onReadiness(readiness);
  }

  Future<void> _enableBluetooth() async {
    await _access.requestEnable();
    await _check();
  }

  void _startScan() {
    final repo = ref.read(diveComputerRepositoryProvider);
    setState(() {
      _found.clear();
      _phase = _Phase.scanning;
    });
    _scanTimer = Timer(DiveComputerScreen.scanTimeout, _stopScan);
    _scan = _source.discover().listen(
      (computer) async {
        final entry = _Found(computer);
        setState(() => _found.add(entry));
        final known = await repo.findByAddress(computer.address);
        if (known != null && mounted) setState(() => entry.known = true);
      },
      onError: (Object _) => _scanEnded(),
      onDone: _scanEnded,
    );
  }

  void _scanEnded() {
    _scanTimer?.cancel();
    if (mounted && _phase == _Phase.scanning) {
      setState(() => _phase = _Phase.scanEnded);
    }
  }

  Future<void> _stopScan() async {
    _scanTimer?.cancel();
    if (_phase != _Phase.scanning) return;
    await _source.stopDiscovery();
    _scanEnded();
  }

  Future<void> _download(DiscoveredComputer computer) async {
    if (!computer.supported) return;
    await _stopScan();
    // Already stopped; waiting on a closed scan can hang.
    unawaited(_scan?.cancel());
    _scan = null;
    setState(() {
      _computer = computer;
      _received = 0;
      _progress = null;
      _pinTimedOut = false;
      _asNewDevice = false;
      _phase = _Phase.transferring;
    });
    await _awake.keepOn(true);
    final result = await _import.download(computer, onEvent: _onEvent);
    await _awake.keepOn(false);
    if (!mounted) return;
    _result = result;

    if (_pinTimedOut) return setState(() => _phase = _Phase.ended);
    switch (result.end) {
      case DownloadEnd.completed when result.dives.isEmpty:
        setState(() => _phase = _Phase.ended);
      case DownloadEnd.completed when result.serialMismatch != null:
        await _confirmSerial(result);
      case DownloadEnd.completed:
        await _openPreview();
      case DownloadEnd.cancelled when result.dives.isNotEmpty:
        await _openPreview();
      case _:
        setState(() => _phase = _Phase.ended);
    }
  }

  void _onEvent(TransferEvent event) {
    if (!mounted) return;
    switch (event) {
      case TransferProgress():
        setState(() => _progress = event);
      case DiveReceived():
        setState(() => _received++);
      case PinRequested():
        _askPin();
      case TransferCompleted() || TransferCancelled() || TransferFailed():
        break;
    }
  }

  Future<void> _askPin() async {
    final computer = _computer!;
    final answer = await showDialog<_PinAnswer>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PinDialog(computer: computer),
    );
    switch (answer) {
      case _PinEntered(:final pin):
        await _import.submitPin(pin);
      case _PinTimedOut():
        _pinTimedOut = true;
        await _import.cancel();
      case _PinCancelled() || null:
        await _import.cancel();
    }
  }

  Future<void> _confirmSerial(DownloadResult result) async {
    final useAsNew = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          icon: const Icon(Icons.warning_amber_outlined),
          title: Text(l10n.serialTitle),
          content: Text(l10n.serialBody(result.serialMismatch!.product)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.serialUseAsNew),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
          ],
        );
      },
    );
    if (!mounted) return;
    if (useAsNew != true) return context.go(ImportScreen.path);
    _asNewDevice = true;
    await _openPreview();
  }

  Future<void> _openPreview() async {
    final diverId = (await ref.read(activeDiverProvider.future))!.id!;
    final checks = await _import.preview(diverId, _result!);
    if (!mounted) return;
    setState(() {
      _checks = checks;
      _phase = _Phase.preview;
    });
  }

  Future<int> _save(
    Set<int> selected,
    Set<int> confirmed,
    List<ImportedDive> dives,
  ) async {
    final diverId = (await ref.read(activeDiverProvider.future))!.id!;
    final r = _result!;
    final saved = await _import.save(
      diverId,
      DownloadResult(
        session: r.session,
        dives: dives,
        end: r.end,
        errorCode: r.errorCode,
        serial: r.serial,
        firmware: r.firmware,
        serialMismatch: r.serialMismatch,
      ),
      selected: selected,
      confirmed: confirmed,
      asNewDevice: _asNewDevice,
    );
    return saved.savedCount;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.importSourceComputer)),
      body: SafeArea(
        child: switch (_phase) {
          _Phase.checking => const SizedBox.shrink(),
          _Phase.blocked => _blocked(l10n),
          _Phase.scanning || _Phase.scanEnded => _search(l10n),
          _Phase.transferring => _transfer(l10n),
          _Phase.ended => _ended(l10n),
          _Phase.preview => ImportPreview(
            source: l10n.previewSourceComputer(_computer!.name),
            notes: [
              if (_result!.end == DownloadEnd.cancelled) l10n.transferCancelled,
              if (_result!.end == DownloadEnd.connectionLost) l10n.transferLost,
            ],
            dives: _result!.dives,
            checks: _checks,
            onSave: _save,
          ),
        },
      ),
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

  Widget _blocked(AppLocalizations l10n) {
    final ios = defaultTargetPlatform == TargetPlatform.iOS;
    final (text, action, onPressed) = switch (_readiness) {
      BluetoothReadiness.off when ios => (l10n.btOff, null, null),
      BluetoothReadiness.off => (l10n.btOff, l10n.btTurnOn, _enableBluetooth),
      BluetoothReadiness.needsPermission => (
        l10n.btExplain,
        l10n.btContinue,
        _requestPermission,
      ),
      BluetoothReadiness.permanentlyDenied || BluetoothReadiness.ready => (
        l10n.btDenied,
        l10n.btOpenSettings,
        _access.openAppSettings,
      ),
    };
    return _message(
      icon: Icons.bluetooth_disabled,
      children: [
        Text(text, style: Theme.of(context).textTheme.titleMedium),
        if (_readiness == BluetoothReadiness.off && ios) ...[
          const SizedBox(height: 8),
          Text(l10n.btTurnOnIos),
        ],
        if (action != null) ...[
          const SizedBox(height: 24),
          FilledButton(onPressed: onPressed, child: Text(action)),
        ],
      ],
    );
  }

  Widget _search(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final scanning = _phase == _Phase.scanning;
    final still = MediaQuery.disableAnimationsOf(context);
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(l10n.scanPairHintEonCore),
        ),
        const SizedBox(height: 16),
        if (scanning)
          ListTile(
            leading: still
                ? const Icon(Icons.radar)
                : const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
            title: Text(l10n.scanRunning),
            trailing: TextButton(
              onPressed: _stopScan,
              child: Text(l10n.scanStop),
            ),
          ),
        for (final entry in _found) _deviceRow(l10n, entry),
        if (!scanning && _found.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.scanNothing, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final item in [
                  l10n.scanCheckBluetooth,
                  l10n.scanCheckDistance,
                  l10n.scanCheckSuuntoApp,
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_box_outline_blank, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(item)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        if (!scanning)
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: _startScan,
              child: Text(l10n.scanAgain),
            ),
          ),
      ],
    );
  }

  Widget _deviceRow(AppLocalizations l10n, _Found entry) {
    final theme = Theme.of(context);
    final muted = theme.extension<DiveColors>()!.onSurfaceMuted;
    final c = entry.computer;
    return InkWell(
      onTap: c.supported ? () => _download(c) : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.watch_outlined,
                color: c.supported ? theme.colorScheme.primary : muted,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: c.supported ? null : muted,
                      ),
                    ),
                    if (c.supported && c.product != c.name) Text(c.product),
                    if (!c.supported) ...[
                      Text(
                        l10n.scanUnsupported,
                        style: TextStyle(color: muted),
                      ),
                      Text(l10n.scanUseFit, style: TextStyle(color: muted)),
                      TextButton(
                        onPressed: () => showFitGuide(context),
                        child: Text(l10n.scanFitGuide),
                      ),
                    ],
                  ],
                ),
              ),
              if (entry.known) Chip(label: Text(l10n.scanKnown)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _transfer(AppLocalizations l10n) {
    final progress = _progress;
    final value = progress == null || progress.total <= 0
        ? null
        : (progress.current / progress.total).clamp(0.0, 1.0);
    return _message(
      icon: Icons.bluetooth_searching,
      children: [
        Text(
          _received == 0
              ? l10n.transferConnecting(_computer!.name)
              : l10n.transferFound(_received),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(value: value),
        const SizedBox(height: 16),
        Text(l10n.transferKeepClose),
        const SizedBox(height: 24),
        OutlinedButton(onPressed: _import.cancel, child: Text(l10n.cancel)),
      ],
    );
  }

  Widget _ended(AppLocalizations l10n) {
    final result = _result!;
    final theme = Theme.of(context);
    Widget reconnect() => FilledButton(
      onPressed: () => _download(_computer!),
      child: Text(l10n.transferReconnect),
    );

    if (_pinTimedOut || result.end == DownloadEnd.cancelled) {
      return _message(
        icon: Icons.timer_off_outlined,
        children: [
          Text(
            _pinTimedOut ? l10n.pinTimeout : l10n.transferCancelled,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          reconnect(),
        ],
      );
    }
    return switch (result.end) {
      DownloadEnd.completed => _message(
        icon: Icons.check_circle_outline,
        children: [
          Text(l10n.transferUpToDate, style: theme.textTheme.titleMedium),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.go(ImportScreen.path),
            child: Text(l10n.transferDone),
          ),
        ],
      ),
      DownloadEnd.connectionLost => _message(
        icon: Icons.bluetooth_disabled,
        children: [
          Text(l10n.transferLost, style: theme.textTheme.titleMedium),
          if (result.dives.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(l10n.transferPartial(result.dives.length)),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: _openPreview,
              child: Text(l10n.transferCheckReceived),
            ),
          ],
          const SizedBox(height: 12),
          reconnect(),
        ],
      ),
      DownloadEnd.failed || DownloadEnd.cancelled => _message(
        icon: Icons.error_outline,
        children: [
          Text(l10n.transferFailed, style: theme.textTheme.titleMedium),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => _download(_computer!),
            child: Text(l10n.retry),
          ),
          if (result.errorCode != null) ...[
            const SizedBox(height: 8),
            Text(
              l10n.errorCode(result.errorCode!),
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.push(DiagnosticsScreen.path),
            child: Text(l10n.sendLogs),
          ),
        ],
      ),
    };
  }
}

sealed class _PinAnswer {
  const _PinAnswer();
}

class _PinEntered extends _PinAnswer {
  const _PinEntered(this.pin);

  final String pin;
}

class _PinCancelled extends _PinAnswer {
  const _PinCancelled();
}

class _PinTimedOut extends _PinAnswer {
  const _PinTimedOut();
}

/// „EON Core (••3F7A) fragt nach einem Code.“ Closes itself after
/// [DiveComputerScreen.pinTimeout] (ui-spec §5.6, security: name the device).
class _PinDialog extends StatefulWidget {
  const _PinDialog({required this.computer});

  final DiscoveredComputer computer;

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final _controller = TextEditingController();
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(
      DiveComputerScreen.pinTimeout,
      () => Navigator.of(context).pop(const _PinTimedOut()),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final pin = _controller.text.trim();
    if (pin.isNotEmpty) Navigator.of(context).pop(_PinEntered(pin));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = widget.computer;
    return AlertDialog(
      title: Text(l10n.pinTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.pinBody(c.name, c.shortId)),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: l10n.pinField),
            onSubmitted: (_) => _confirm(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(const _PinCancelled()),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _confirm, child: Text(l10n.pinConfirm)),
      ],
    );
  }
}
