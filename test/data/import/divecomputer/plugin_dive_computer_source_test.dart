// T18.1-T18.8: the libdivecomputer plugin as DiveComputerSource (ADR 0002).
import 'dart:typed_data';

import 'package:divedown/data/import/divecomputer/plugin_dive_computer_source.dart';
import 'package:divedown/domain/import/dive_computer_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libdivecomputer_plugin/libdivecomputer_plugin.dart' as dc;

/// Records host calls instead of talking to the platform.
class _FakeHostApi extends dc.DiveComputerHostApi {
  final calls = <String>[];
  String? fingerprint;

  @override
  Future<void> startDiscovery(dc.TransportType transport) async =>
      calls.add('startDiscovery:${transport.name}');

  @override
  Future<void> stopDiscovery() async => calls.add('stopDiscovery');

  @override
  Future<void> startDownload(
    dc.DiscoveredDevice device,
    String? fingerprint,
    bool syncClock,
  ) async {
    calls.add('startDownload:${device.address}:$syncClock');
    this.fingerprint = fingerprint;
  }

  @override
  Future<void> cancelDownload() async => calls.add('cancelDownload');

  @override
  Future<void> submitPinCode(String pinCode) async => calls.add('pin:$pinCode');
}

dc.DiscoveredDevice _device({
  String address = 'D4:22:CD:00:3F:7A',
  String? name = 'EON Core',
  int model = 1,
  String product = 'EON Core',
}) => dc.DiscoveredDevice(
  vendor: 'Suunto',
  product: product,
  model: model,
  address: address,
  name: name,
  transport: dc.TransportType.ble,
);

const _computer = DiscoveredComputer(
  name: 'EON Core',
  vendor: 'Suunto',
  product: 'EON Core',
  model: 1,
  address: 'D4:22:CD:00:3F:7A',
);

dc.ParsedDive _parsed(String fingerprint) => dc.ParsedDive(
  fingerprint: fingerprint,
  dateTimeYear: 2026,
  dateTimeMonth: 11,
  dateTimeDay: 13,
  dateTimeHour: 6,
  dateTimeMinute: 0,
  dateTimeSecond: 0,
  maxDepthMeters: 18.4,
  avgDepthMeters: 0,
  durationSeconds: 2820,
  samples: [
    dc.ProfileSample(timeSeconds: 0, depthMeters: 0),
    dc.ProfileSample(timeSeconds: 60, depthMeters: 18.4),
  ],
  tanks: const [],
  gasMixes: const [],
  events: const [],
);

void main() {
  late _FakeHostApi host;
  late dc.DiveComputerService service;
  late PluginDiveComputerSource source;

  setUp(() {
    host = _FakeHostApi();
    service = dc.DiveComputerService(hostApi: host);
    source = PluginDiveComputerSource(service);
  });

  tearDown(() => service.dispose());

  test('T18.1 scan: BLE only, each address once, ends with the scan', () async {
    final found = <DiscoveredComputer>[];
    final done = source.discover().forEach(found.add);
    await pumpEventQueue();

    service.onDeviceDiscovered(_device());
    service.onDeviceDiscovered(_device());
    service.onDeviceDiscovered(_device(address: 'AA:00', name: null));
    service.onDiscoveryComplete();
    await done;

    expect(host.calls, ['startDiscovery:ble']);
    expect(found, hasLength(2));
    expect(found.first.name, 'EON Core');
    expect(found.first.product, 'EON Core');
    expect(found.first.supported, isTrue);
    // No advertised name: the product stands in.
    expect(found.last.name, 'EON Core');
  });

  test('T18.2 unsupported model stays visible but marked', () async {
    final found = <DiscoveredComputer>[];
    final done = source.discover().forEach(found.add);
    await pumpEventQueue();

    service.onDeviceDiscovered(
      _device(name: 'Suunto Ocean', product: 'Ocean', model: -1),
    );
    await source.stopDiscovery();
    await done;

    expect(found.single.supported, isFalse);
    expect(host.calls.last, 'stopDiscovery');
  });

  test('T18.3 fingerprint goes to the plugin as hex, no clock sync', () async {
    source.download(
      _computer,
      sinceFingerprint: Uint8List.fromList([0x55, 0x76, 0x00, 0x6a]),
    );
    await pumpEventQueue();

    expect(host.calls, ['startDownload:D4:22:CD:00:3F:7A:false']);
    expect(host.fingerprint, '5576006a');

    source.download(_computer);
    await pumpEventQueue();
    expect(host.fingerprint, isNull);
  });

  test('T18.4 dives are translated by the adapter, '
      'completion ends the stream', () async {
    final events = <TransferEvent>[];
    final done = source.download(_computer).forEach(events.add);
    await pumpEventQueue();

    service.onDownloadProgress(
      dc.DownloadProgress(current: 10, total: 40, status: 'downloading'),
    );
    service.onDiveDownloaded(_parsed('5576006a'));
    service.onDownloadComplete(1, '1234', '4.0.1131', null, null, null);
    await done;

    expect(events[0], isA<TransferProgress>());
    expect((events[0] as TransferProgress).total, 40);
    final dive = (events[1] as DiveReceived).dive;
    expect(dive.sourceId, 'EON Core:5576006a');
    // Adapter ran: mean depth from samples, not the EON Core's 0.
    expect(dive.avgDepthM, isNot(0));
    final end = events[2] as TransferCompleted;
    expect(end.serial, '1234');
    expect(end.firmware, '4.0.1131');
  });

  test(
    'T18.5 cancel ends the stream even if the plugin stays silent (BLE)',
    () async {
      final events = <TransferEvent>[];
      final done = source.download(_computer).forEach(events.add);
      await pumpEventQueue();
      service.onDiveDownloaded(_parsed('01'));

      await source.cancel();
      await done;

      expect(host.calls.last, 'cancelDownload');
      expect(events.last, isA<TransferCancelled>());
      expect(events.whereType<DiveReceived>(), hasLength(1));
    },
  );

  test(
    'T18.6 dives the plugin flushes after a cancel still arrive (USB)',
    () async {
      final events = <TransferEvent>[];
      final done = source.download(_computer).forEach(events.add);
      await pumpEventQueue();

      await source.cancel();
      service.onDiveDownloaded(_parsed('02'));
      service.onDownloadComplete(0, null, null, null, null, null);
      await done;

      expect(events.whereType<TransferCompleted>(), isEmpty);
      expect(events.whereType<TransferCancelled>(), hasLength(1));
    },
  );

  group('T18.7 errors', () {
    for (final (code, lost) in [
      ('connect_failed', true),
      ('bond_failed', true),
      ('not_found', true),
      ('download_error', true),
      ('download_crashed', false),
      ('session_failed', false),
    ]) {
      test('$code → connectionLost: $lost', () async {
        final events = <TransferEvent>[];
        final done = source.download(_computer).forEach(events.add);
        await pumpEventQueue();

        service.onError(dc.DiveComputerError(code: code, message: 'm'));
        await done;

        final failed = events.single as TransferFailed;
        expect(failed.code, code);
        expect(failed.connectionLost, lost);
      });
    }
  });

  test('T18.8 PIN request and answer', () async {
    final events = <TransferEvent>[];
    source.download(_computer).listen(events.add);
    await pumpEventQueue();

    service.onPinCodeRequired('D4:22:CD:00:3F:7A');
    await pumpEventQueue();
    await source.submitPin('123456');

    expect(events.single, isA<PinRequested>());
    expect(host.calls.last, 'pin:123456');
  });

  test('T18.9 short id is the end of the address', () {
    expect(_computer.shortId, '3F7A');
    const ios = DiscoveredComputer(
      name: 'EON Core',
      vendor: 'Suunto',
      product: 'EON Core',
      model: 1,
      address: '6F1C2E4A-0B3D-4E5F-9A8B-7C6D5E4F3A2B',
    );
    expect(ios.shortId, '3A2B');
  });
}
