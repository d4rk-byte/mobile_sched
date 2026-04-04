// lib/utils/constants.dart

import 'package:flutter/material.dart';

const String apiBaseUrl = 'http://localhost:8000/api';

// Semester options
const List<String> semesterOptions = [
  '1st Semester',
  '2nd Semester',
  'Summer',
];

// Days of week
const List<String> daysOfWeek = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

// Request statuses
const String statusPending = 'pending';
const String statusApproved = 'approved';
const String statusRejected = 'rejected';
const String statusCancelled = 'cancelled';

const Map<String, String> statusLabels = {
  statusPending: 'Pending',
  statusApproved: 'Approved',
  statusRejected: 'Rejected',
  statusCancelled: 'Cancelled',
};

const Map<String, Color> statusColors = {
  statusPending: Color(0xFFF59E0B),
  statusApproved: Color(0xFF10B981),
  statusRejected: Color(0xFFEF4444),
  statusCancelled: Color(0xFF6B7280),
};
