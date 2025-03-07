import 'package:flutter/material.dart';

extension TimeOfDayExtension on TimeOfDay {
  bool operator <(TimeOfDay other) {
    if (hour < other.hour) {
      return true;
    } else if (hour == other.hour && minute < other.minute) {
      return true;
    } else {
      return false;
    }
  }

  bool operator <=(TimeOfDay other) {
    if (hour < other.hour) {
      return true;
    } else if (hour == other.hour && minute <= other.minute) {
      return true;
    } else {
      return false;
    }
  }

  bool operator >(TimeOfDay other) {
    if (hour > other.hour) {
      return true;
    } else if (hour == other.hour && minute > other.minute) {
      return true;
    } else {
      return false;
    }
  }

  static TimeOfDay fromString(String timeString) {
    List<String> split = timeString.split(':');
    return TimeOfDay(hour: int.parse(split[0]), minute: int.parse(split[1]));
  }
}

extension DateTimeExtension on DateTime {
  static DateTime parseTime(String timeString, {DateTime? date}) {
    final time = TimeOfDay(
      hour: int.parse(timeString.split(':')[0]),
      minute: int.parse(timeString.split(':')[1]),
    );
    final dateTime = date ?? DateTime.now();
    return DateTime(
        dateTime.year, dateTime.month, dateTime.day, time.hour, time.minute);
  }
}
