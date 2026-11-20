import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/database.dart';

/// The open database. Set by [AppStartupGate] once the file is open;
/// tests override it with an in-memory database.
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('appDatabaseProvider must be overridden'),
);
