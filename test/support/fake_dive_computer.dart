// Fakes for the BLE import: dive computer source, Bluetooth access, screen.
import 'dart:async';
import 'dart:typed_data';

import 'package:divedown/domain/dive/dive.dart';
import 'package:divedown/domain/import/bluetooth_access.dart';
import 'package:divedown/domain/import/dive_computer_source.dart';
import 'package:divedown/domain/import/imported_dive.dart';

const eonCore = DiscoveredComputer(
  name: 'EON Core',
  vendor: 'Suunto',
  product: 'EON Core',
  model: 1,
  address: 'D4:22:CD:00:3F:7A',
);

const suuntoOcean = DiscoveredComputer(
  name: 'Suunto Ocean',
  vendor: 'Suunto',
  product: 'Ocean',
  model: DiscoveredComputer.unsupportedModel,
  address: 'D4:22:CD:00:91:B0',
);

/// A dive as the EON Core adapter delivers it: Nov [day], [hour]:00.
ImportedDive computerDive(
  int day, {
  int hour = 9,
  double maxDepthM = 18.4,
  int durationS = 2820,
  int? fingerprint,
}) => ImportedDive(
  source: DiveSource.diveComputer,
  sourceId: 'EON Core:${fingerprint ?? day}',
  start: DateTime.utc(2026, 11, day, hour),
  durationS: durationS,
  maxDepthM: maxDepthM,
  samples: [
    const DiveSample(timeS: 0, depthM: 0),
    DiveSample(timeS: durationS ~/ 2, depthM: maxDepthM),
    DiveSample(timeS: durationS, depthM: 0),
  ],
  fingerprint: Uint8List.fromList([fingerprint ?? day]),
);

/// Plays back a scripted download, or lets the test push events by hand.
class FakeDiveComputerSource implements DiveComputerSource {
  /// Devices [discover] reports right away.
  List<DiscoveredComputer> devices = [eonCore];

  /// When true, the scan keeps running until [stopDiscovery] (or [endScan]).
  bool scanRunsUntilStopped = true;

  /// Events sent right after [download] starts. Null: the test calls [emit].
  List<TransferEvent>? script;

  int discoverCalls = 0;
  int stopDiscoveryCalls = 0;
  int cancelCalls = 0;
  final pins = <String>[];
  final downloads = <({DiscoveredComputer computer, Uint8List? since})>[];

  StreamController<DiscoveredComputer>? _scan;
  StreamController<TransferEvent>? _transfer;

  bool get downloading => _transfer != null && !_transfer!.isClosed;

  @override
  Stream<DiscoveredComputer> discover() {
    discoverCalls++;
    final scan = _scan = StreamController<DiscoveredComputer>();
    scheduleMicrotask(() {
      devices.forEach(scan.add);
      if (!scanRunsUntilStopped) scan.close();
    });
    return scan.stream;
  }

  /// Ends the scan as the platform would.
  void endScan() => _scan?.close();

  @override
  Future<void> stopDiscovery() async {
    stopDiscoveryCalls++;
    await _scan?.close();
  }

  @override
  Stream<TransferEvent> download(
    DiscoveredComputer computer, {
    Uint8List? sinceFingerprint,
  }) {
    downloads.add((computer: computer, since: sinceFingerprint));
    final transfer = _transfer = StreamController<TransferEvent>();
    final events = script;
    if (events != null) {
      scheduleMicrotask(() async {
        for (final e in events) {
          if (transfer.isClosed) return;
          emit(e);
          await Future<void>.delayed(Duration.zero);
        }
      });
    }
    return transfer.stream;
  }

  /// Sends [event]; the last ones close the stream as the plugin would.
  void emit(TransferEvent event) {
    final transfer = _transfer!;
    transfer.add(event);
    if (event is TransferCompleted ||
        event is TransferCancelled ||
        event is TransferFailed) {
      transfer.close();
    }
  }

  @override
  Future<void> submitPin(String pin) async => pins.add(pin);

  @override
  Future<void> cancel() async {
    cancelCalls++;
    if (downloading) emit(const TransferCancelled());
  }
}

class FakeBluetoothAccess implements BluetoothAccess {
  FakeBluetoothAccess([this.state = BluetoothReadiness.ready]);

  BluetoothReadiness state;

  /// What the system permission dialog leads to.
  BluetoothReadiness afterRequest = BluetoothReadiness.ready;

  int permissionRequests = 0;
  int enableRequests = 0;
  int settingsOpened = 0;

  @override
  Future<BluetoothReadiness> check() async => state;

  @override
  Future<BluetoothReadiness> requestPermission() async {
    permissionRequests++;
    return state = afterRequest;
  }

  @override
  Future<void> requestEnable() async => enableRequests++;

  @override
  Future<void> openAppSettings() async => settingsOpened++;
}

class FakeScreenAwake implements ScreenAwake {
  final calls = <bool>[];

  bool get on => calls.isNotEmpty && calls.last;

  @override
  Future<void> keepOn(bool on) async => calls.add(on);
}
