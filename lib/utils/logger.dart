import 'package:flutter/foundation.dart';

class Logger {
  // Logs a message only when in debug mode
  static void log(String message) {
    if (kDebugMode) {
      print(message);
    }
  }

  // Logs an error message with optional stack trace
  static void error(String message, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      print("ERROR: $message");
      if (stackTrace != null) {
        print(stackTrace);
      }
    }
  }

  // Logs a warning message
  static void warn(String message) {
    if (kDebugMode) {
      print("WARNING: $message");
    }
  }

  // Logs an info message
  static void info(String message) {
    if (kDebugMode) {
      print("INFO: $message");
    }
  }
}
