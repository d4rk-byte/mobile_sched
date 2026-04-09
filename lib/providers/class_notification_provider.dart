// lib/providers/class_notification_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/class_notification_service.dart';

final classNotificationServiceProvider =
    Provider<ClassNotificationService>((ref) {
  return ClassNotificationService();
});
