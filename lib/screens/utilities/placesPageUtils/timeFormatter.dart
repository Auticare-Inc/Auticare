// File: lib/utils/time_formatter.dart
import 'package:flutter/material.dart';

class TimeFormatter {
  static String formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
