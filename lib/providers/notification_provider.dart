// lib/providers/notification_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import 'api_provider.dart';

final notificationsProvider = FutureProvider<NotificationsResponse>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final response = await apiService.getNotifications();
  return NotificationsResponse.fromJson(response);
});

final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getUnreadNotificationCount();
});
