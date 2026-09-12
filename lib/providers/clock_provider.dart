import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Current time, overridable in tests so date-based logic stays deterministic.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
