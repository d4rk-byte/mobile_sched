// lib/providers/notification_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import 'api_provider.dart';

class NotificationOptimisticState {
  final bool markAllRead;
  final Set<int> markedReadIds;

  const NotificationOptimisticState({
    this.markAllRead = false,
    this.markedReadIds = const <int>{},
  });

  bool get hasOverrides => markAllRead || markedReadIds.isNotEmpty;

  NotificationOptimisticState copyWith({
    bool? markAllRead,
    Set<int>? markedReadIds,
  }) {
    return NotificationOptimisticState(
      markAllRead: markAllRead ?? this.markAllRead,
      markedReadIds: markedReadIds ?? this.markedReadIds,
    );
  }

  bool isRead(int id) {
    if (markAllRead) {
      return true;
    }

    return markedReadIds.contains(id);
  }

  int applyToUnreadCount(int unreadCount) {
    if (markAllRead) {
      return 0;
    }

    final adjusted = unreadCount - markedReadIds.length;
    return adjusted < 0 ? 0 : adjusted;
  }
}

final notificationOptimisticStateProvider =
    StateProvider<NotificationOptimisticState>(
  (ref) => const NotificationOptimisticState(),
);

final notificationsProvider =
    FutureProvider<NotificationsResponse>((ref) async {
  final apiService = ref.watch(apiServiceProvider);

  if (!apiService.hasToken) {
    return NotificationsResponse(
      notifications: const <NotificationItem>[],
      unreadCount: 0,
    );
  }

  final response = await apiService.getNotifications();
  return NotificationsResponse.fromJson(response);
});

final effectiveNotificationsProvider =
    Provider<AsyncValue<NotificationsResponse>>((ref) {
  final notificationsAsync = ref.watch(notificationsProvider);
  final optimisticState = ref.watch(notificationOptimisticStateProvider);

  return notificationsAsync.whenData((payload) {
    if (!optimisticState.hasOverrides) {
      return payload;
    }

    final patchedNotifications = payload.notifications
        .map(
          (item) => optimisticState.isRead(item.id) && !item.read
              ? item.copyWith(read: true)
              : item,
        )
        .toList();

    return NotificationsResponse(
      notifications: patchedNotifications,
      unreadCount: patchedNotifications.where((item) => !item.read).length,
    );
  });
});

final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  final apiService = ref.watch(apiServiceProvider);

  if (!apiService.hasToken) {
    return 0;
  }

  return await apiService.getUnreadNotificationCount();
});

final effectiveUnreadNotificationCountProvider = Provider<int>((ref) {
  final serverUnreadCount =
      ref.watch(unreadNotificationCountProvider).maybeWhen(
            data: (count) => count,
            orElse: () => 0,
          );
  final optimisticState = ref.watch(notificationOptimisticStateProvider);

  return optimisticState.applyToUnreadCount(serverUnreadCount);
});
