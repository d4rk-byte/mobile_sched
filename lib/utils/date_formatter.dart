// lib/utils/date_formatter.dart

import 'package:intl/intl.dart';

class DateFormatter {
  static String formatTime(String time) {
    try {
      final parsedTime = DateFormat('HH:mm').parse(time);
      return DateFormat('hh:mm a').format(parsedTime);
    } catch (e) {
      return time;
    }
  }

  static String formatDateTime(String dateTime) {
    try {
      final parsed = DateTime.parse(dateTime);
      return DateFormat('MMM dd, yyyy HH:mm').format(parsed);
    } catch (e) {
      return dateTime;
    }
  }

  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatDateShort(DateTime date) {
    return DateFormat('MMM dd').format(date);
  }

  static String formatTime24(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  static String formatTime12(DateTime time) {
    return DateFormat('hh:mm a').format(time);
  }

  static String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return formatDate(dateTime);
    }
  }
}
