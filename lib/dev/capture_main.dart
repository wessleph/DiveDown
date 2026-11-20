// Developer tool, debug builds only: records raw dive data from a dive
// computer over BLE as test fixtures (tasks.md T4.5). Not part of the app;
// nothing in lib/main.dart imports it, so release builds never contain it.
//
//   flutter run -t lib/dev/capture_main.dart
//
// Files land in <Application Support>/capture/, per dive:
//   <start>_<fingerprint>.bin            raw dive data from libdivecomputer
//   <start>_<fingerprint>.expected.json  device and parsed summary for the test
// The serial number is deliberately not written (security.md §3).
// German texts are inline on purpose: this screen is never shipped.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:libdivecomputer_plugin/libdivecomputer_plugin.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Stops after this many dives so a full logbook is not read for a fixture.
const _maxDives = 3;

void main() {
  if (kReleaseMode) {
    throw StateError('The capture tool runs in debug builds only.');
  }
  runApp(const MaterialApp(home: CaptureScreen()));
}

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final _service = DiveComputerService();
  final _devices = <String, DiscoveredDevice>{};
  final _log = <String>[];
  final _subscriptions = <StreamSubscription<Object?>>[];
  Directory? _folder;
  bool _scanning = false;
  bool _downloading = false;
  int _saved = 0;
  String _progress = '';
  DiscoveredDevice? _device;

  @override
  void initState() {
    super.initState();
    DiveComputerFlutterApi.setUp(_service);
    _subscriptions
      ..add(
        _service.discoveredDevices.listen(
          (d) => setState(() => _devices[d.address] = d),
        ),
      )
      ..add(
        _service.discoveryComplete.listen(
          (_) => setState(() => _scanning = false),
        ),
      )
      ..add(_service.downloadEvents.listen(_onDownloadEvent))
      ..add(
        _service.logEvents.listen((e) {
          if (e.level != 'debug') debugPrint('[${e.category}] ${e.message}');
        }),
      );
    _prepareFolder();
    _service.getVersion().then((v) => _add('libdivecomputer $v'));
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    DiveComputerFlutterApi.setUp(null);
    _service.dispose();
    super.dispose();
  }

  Future<void> _prepareFolder() async {
    final support = await getApplicationSupportDirectory();
    final folder = Directory(p.join(support.path, 'capture'));
    await folder.create(recursive: true);
    setState(() => _folder = folder);
    _add('Ziel: ${folder.path}');
  }

  void _add(String line) {
    debugPrint('capture: $line');
    if (mounted) setState(() => _log.insert(0, line));
  }

  Future<void> _scan() async {
    setState(() {
      _devices.clear();
      _scanning = true;
    });
    try {
      await _service.startDiscovery(TransportType.ble);
    } on Exception catch (e) {
      _add('Suche fehlgeschlagen: $e');
      setState(() => _scanning = false);
    }
  }

  Future<void> _download(DiscoveredDevice device) async {
    if (_scanning) await _service.stopDiscovery();
    setState(() {
      _scanning = false;
      _downloading = true;
      _saved = 0;
      _device = device;
    });
    _add('Verbinde mit ${device.vendor} ${device.product} …');
    try {
      // No fingerprint: start with the newest dive on the computer.
      await _service.startDownload(device);
    } on Exception catch (e) {
      _add('Download fehlgeschlagen: $e');
      setState(() => _downloading = false);
    }
  }

  Future<void> _onDownloadEvent(DownloadEvent event) async {
    switch (event) {
      case DownloadProgressEvent(:final progress):
        setState(() => _progress = '${progress.current} / ${progress.total}');
      case DiveDownloadedEvent(:final dive):
        await _saveDive(dive);
        if (_saved >= _maxDives && _downloading) {
          _add('$_maxDives Tauchgänge gespeichert, breche ab.');
          await _service.cancelDownload();
        }
      case DownloadCompleteEvent(:final totalDives, :final firmwareVersion):
        _add(
          'Fertig: $totalDives gelesen, $_saved gespeichert '
          '(Firmware ${firmwareVersion ?? '?'}).',
        );
        setState(() => _downloading = false);
      case DownloadErrorEvent(:final error):
        _add('Fehler ${error.code}: ${error.message}');
        setState(() => _downloading = false);
      case PinCodeRequestEvent():
        await _askPin();
    }
  }

  Future<void> _saveDive(ParsedDive dive) async {
    final raw = dive.rawData;
    final folder = _folder;
    if (raw == null || folder == null) {
      _add('Tauchgang ohne Rohdaten übersprungen.');
      return;
    }
    String two(int n) => n.toString().padLeft(2, '0');
    final start =
        '${dive.dateTimeYear}-${two(dive.dateTimeMonth)}-'
        '${two(dive.dateTimeDay)}T${two(dive.dateTimeHour)}'
        '${two(dive.dateTimeMinute)}${two(dive.dateTimeSecond)}';
    final base = p.join(folder.path, '${start}_${dive.fingerprint}');

    await File('$base.bin').writeAsBytes(raw);
    final device = _device!;
    final expected = {
      'vendor': device.vendor,
      'product': device.product,
      'model': device.model,
      'fingerprint': dive.fingerprint,
      'start': start,
      'utc_offset_s': dive.dateTimeTimezoneOffset,
      'max_depth_m': dive.maxDepthMeters,
      'avg_depth_m': dive.avgDepthMeters,
      'duration_s': dive.durationSeconds,
      'min_temperature_c': dive.minTemperatureCelsius,
      'sample_count': dive.samples.length,
      'tank_count': dive.tanks.length,
      'gas_mix_count': dive.gasMixes.length,
      'event_count': dive.events.length,
      'raw_bytes': raw.length,
    };
    await File('$base.expected.json')
        .writeAsString(const JsonEncoder.withIndent('  ').convert(expected));
    _saved++;
    _add(
      'Gespeichert: $start, ${dive.maxDepthMeters.toStringAsFixed(1)} m, '
      '${(dive.durationSeconds / 60).round()} min, '
      '${dive.samples.length} Samples, ${raw.length} Bytes',
    );
  }

  Future<void> _askPin() async {
    final controller = TextEditingController();
    final pin = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('PIN vom Tauchcomputer'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'PIN'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Senden'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (pin == null || pin.isEmpty) {
      await _service.cancelDownload();
      return;
    }
    await _service.submitPinCode(pin);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tauchcomputer-Aufnahme (Debug)')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                FilledButton.icon(
                  onPressed: _scanning || _downloading ? null : _scan,
                  icon: const Icon(Icons.bluetooth_searching),
                  label: Text(_scanning ? 'Suche läuft …' : 'Suchen'),
                ),
                const SizedBox(width: 8),
                if (_downloading)
                  OutlinedButton(
                    onPressed: _service.cancelDownload,
                    child: const Text('Abbrechen'),
                  ),
              ],
            ),
          ),
          if (_downloading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Übertragung $_progress · $_saved gespeichert'),
            ),
          for (final d in _devices.values)
            ListTile(
              leading: const Icon(Icons.watch_outlined),
              title: Text('${d.vendor} ${d.product}'),
              subtitle: Text('${d.name ?? '?'} · ${d.address}'),
              enabled: !_downloading,
              onTap: () => _download(d),
            ),
          const Divider(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [for (final line in _log) Text(line)],
            ),
          ),
        ],
      ),
    );
  }
}
