// Derived from Submersion (https://github.com/submersion-app/submersion), commit e78a87cb, GPL-3.0. Modified for DiveDown.

import Flutter

public class LibdivecomputerPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let messenger = registrar.messenger()
        let api = DiveComputerHostApiImpl(messenger: messenger)
        DiveComputerHostApiSetup.setUp(binaryMessenger: messenger, api: api)
        NativeLogger.flutterApi = DiveComputerFlutterApi(binaryMessenger: messenger)
    }
}
