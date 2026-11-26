import Flutter
import HealthKit

/// Apple Health, read only (security.md G3, ui-spec §5.10, T6).
/// Counterpart of lib/data/platform/health_channel.dart.
///
/// Delivers raw underwater diving workouts: no merging, no rounding. Turning
/// them into dives happens in Dart (lib/data/import/health/), where it is
/// tested without a phone. Never logs or sends any value.
final class HealthDiveChannel {
  private let store = HKHealthStore()
  private let channel: FlutterMethodChannel

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(
      name: "io.github.wessleph.divedown/health", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result)
    }
  }

  private func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    switch call.method {
    case "availability":
      result(availability())
    case "requestReadAccess":
      guard #available(iOS 17.0, *) else {
        result(FlutterError(code: "needs_ios_17", message: nil, details: nil))
        return
      }
      requestReadAccess(result)
    case "diveWorkouts":
      guard #available(iOS 17.0, *) else {
        result(FlutterError(code: "needs_ios_17", message: nil, details: nil))
        return
      }
      guard let args = call.arguments as? [String: Any],
        let from = args["from"] as? NSNumber,
        let to = args["to"] as? NSNumber
      else {
        result(FlutterError(code: "bad_arguments", message: nil, details: nil))
        return
      }
      diveWorkouts(
        from: Date(timeIntervalSince1970: from.doubleValue / 1000),
        to: Date(timeIntervalSince1970: to.doubleValue / 1000),
        result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Depth and water temperature exist in HealthKit from iOS 16, the diving
  /// workout type `underwaterDiving` only from iOS 17 (T6.10).
  private func availability() -> String {
    guard HKHealthStore.isHealthDataAvailable() else { return "unavailable" }
    if #available(iOS 17.0, *) { return "available" }
    return "needsNewerIos"
  }

  /// Exactly what the import needs, nothing to write (security.md G3).
  @available(iOS 17.0, *)
  private var readTypes: Set<HKObjectType> {
    [
      HKObjectType.workoutType(),
      HKQuantityType(.underwaterDepth),
      HKQuantityType(.waterTemperature),
      HKQuantityType(.heartRate),
    ]
  }

  /// iOS never tells whether reading was allowed (T6.9), so a completed
  /// dialog is all there is to report.
  @available(iOS 17.0, *)
  private func requestReadAccess(_ result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable() else {
      result(FlutterError(code: "unavailable", message: nil, details: nil))
      return
    }
    store.requestAuthorization(toShare: nil, read: readTypes) { _, error in
      DispatchQueue.main.async {
        if error != nil {
          result(FlutterError(code: "authorization_failed", message: nil, details: nil))
        } else {
          result(nil)
        }
      }
    }
  }

  @available(iOS 17.0, *)
  private func diveWorkouts(from: Date, to: Date, _ result: @escaping FlutterResult) {
    let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
      HKQuery.predicateForSamples(withStart: from, end: to, options: .strictStartDate),
      HKQuery.predicateForWorkouts(with: HKWorkoutActivityType.underwaterDiving),
    ])
    let query = HKSampleQuery(
      sampleType: .workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit,
      sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
    ) { [weak self] _, samples, error in
      guard let self else { return }
      if error != nil {
        DispatchQueue.main.async {
          result(FlutterError(code: "query_failed", message: nil, details: nil))
        }
        return
      }
      self.collect((samples as? [HKWorkout]) ?? [], result)
    }
    store.execute(query)
  }

  /// One workout after the other, one series after the other: the
  /// callbacks never run at the same time, so `out` needs no lock.
  @available(iOS 17.0, *)
  private func collect(_ workouts: [HKWorkout], _ result: @escaping FlutterResult) {
    var out: [[String: Any]] = []
    let bpm = HKUnit.count().unitDivided(by: .minute())
    func next(_ i: Int) {
      guard i < workouts.count else {
        DispatchQueue.main.async { result(out) }
        return
      }
      let w = workouts[i]
      series(.underwaterDepth, .meter(), w) { depth in
        // Without depth there is no dive. A failed depth query (no access,
        // phone locked) is an error, not „Training ohne Tiefe“ (review W2).
        guard let depth else {
          DispatchQueue.main.async {
            result(FlutterError(code: "query_failed", message: nil, details: nil))
          }
          return
        }
        self.series(.waterTemperature, .degreeCelsius(), w) { temperature in
          self.series(.heartRate, bpm, w) { heartRate in
            out.append([
              "uuid": w.uuid.uuidString,
              "start": Self.ms(w.startDate),
              "end": Self.ms(w.endDate),
              "utcOffsetS": Self.utcOffset(w),
              "depth": depth,
              "temperature": temperature ?? [],
              "heartRate": heartRate ?? [],
            ])
            next(i + 1)
          }
        }
      }
    }
    next(0)
  }

  /// Every reading of one type during [workout], also those inside series
  /// samples (heart rate is often stored as a series); nil when the query
  /// failed. Readings of overlapping series outside the workout are dropped
  /// in Dart.
  private func series(
    _ id: HKQuantityTypeIdentifier, _ unit: HKUnit, _ workout: HKWorkout,
    _ done: @escaping ([[Double]]?) -> Void
  ) {
    var points: [[Double]] = []
    var finished = false
    let query = HKQuantitySeriesSampleQuery(
      quantityType: HKQuantityType(id),
      predicate: HKQuery.predicateForSamples(
        withStart: workout.startDate, end: workout.endDate, options: [])
    ) { _, quantity, interval, _, last, error in
      guard !finished else { return }
      if error != nil {
        finished = true
        done(nil)
        return
      }
      if let quantity, let interval {
        points.append([Self.ms(interval.start), quantity.doubleValue(for: unit)])
      }
      if last {
        finished = true
        done(points)
      }
    }
    store.execute(query)
  }

  private static func ms(_ date: Date) -> Double {
    (date.timeIntervalSince1970 * 1000).rounded()
  }

  /// The watch's time zone at the start when it stored one, else the
  /// phone's (T6.1). Dart has no time zone database, so it is worked out here.
  private static func utcOffset(_ workout: HKWorkout) -> Int {
    let stored = (workout.metadata?[HKMetadataKeyTimeZone] as? String)
      .flatMap(TimeZone.init(identifier:))
    return (stored ?? TimeZone.current).secondsFromGMT(for: workout.startDate)
  }
}
