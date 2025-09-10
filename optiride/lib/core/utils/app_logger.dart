import 'package:flutter/foundation.dart';

void logDebug(String message, {Object? error}) {
  if (kDebugMode) {
    final time = DateTime.now().toIso8601String();
    // Simple format
    // ignore: avoid_print
    print('[OPTIRIDE][DEBUG][$time] $message${error != null ? ' | $error' : ''}');
  }
}
