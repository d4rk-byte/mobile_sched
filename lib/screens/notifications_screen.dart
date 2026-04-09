import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../providers/api_provider.dart';
import '../providers/notification_provider.dart';
import '../utils/theme.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _isMarkingAll = false;
  final Set<int> _processingIds = <int>{};

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _refresh() async {
    ref.invalidate(unreadNotificationCountProvider);
    ref.invalidate(notificationsProvider);
    await Future.wait([
      ref.read(notificationsProvider.future),
      ref.read(unreadNotificationCountProvider.future),
    ]);

    ref.read(notificationOptimisticStateProvider.notifier).state =
        const NotificationOptimisticState();
  }

  Future<void> _markAllAsRead() async {
    if (_isMarkingAll) {
      return;
    }

    final optimisticNotifier =
        ref.read(notificationOptimisticStateProvider.notifier);
    final previousOptimisticState =
        ref.read(notificationOptimisticStateProvider);

    optimisticNotifier.state = previousOptimisticState.copyWith(
      markAllRead: true,
    );

    setState(() {
      _isMarkingAll = true;
    });

    try {
      await ref.read(apiServiceProvider).markAllNotificationsRead();
      await _refresh();
      _showMessage('All notifications marked as read.');
    } catch (e) {
      optimisticNotifier.state = previousOptimisticState;
      _showMessage('Unable to mark all as read: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isMarkingAll = false;
        });
      }
    }
  }

  Future<void> _markAsRead(NotificationItem item) async {
    if (item.read || _processingIds.contains(item.id)) {
      return;
    }

    final optimisticNotifier =
        ref.read(notificationOptimisticStateProvider.notifier);
    final previousOptimisticState =
        ref.read(notificationOptimisticStateProvider);

    if (!previousOptimisticState.isRead(item.id)) {
      optimisticNotifier.state = previousOptimisticState.copyWith(
        markedReadIds: <int>{
          ...previousOptimisticState.markedReadIds,
          item.id,
        },
      );
    }

    setState(() {
      _processingIds.add(item.id);
    });

    try {
      await ref.read(apiServiceProvider).markNotificationRead(item.id);
      await _refresh();
    } catch (e) {
      optimisticNotifier.state = previousOptimisticState;
      _showMessage('Unable to update notification: $e');
    } finally {
      if (mounted) {
        setState(() {
          _processingIds.remove(item.id);
        });
      }
    }
  }

  Future<void> _openNotification(NotificationItem item) async {
    if (!item.read) {
      unawaited(_markAsRead(item));
    }

    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _NotificationDetailSheet(item: item);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(effectiveNotificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          notificationsAsync.maybeWhen(
            data: (notifications) {
              if (notifications.unreadCount <= 0) {
                return const SizedBox.shrink();
              }

              return IconButton(
                tooltip: 'Mark all as read',
                onPressed: _isMarkingAll ? null : _markAllAsRead,
                icon: _isMarkingAll
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.done_all_rounded),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) => RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _NotificationSummaryCard(notifications: notifications),
              const SizedBox(height: 16),
              if (notifications.notifications.isEmpty)
                const _NotificationsEmptyState()
              else
                ...notifications.notifications.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _NotificationCard(
                      item: item,
                      isProcessing: _processingIds.contains(item.id),
                      onTap: () => _openNotification(item),
                    ),
                  ),
                ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _NotificationsErrorState(
          message: error.toString(),
          onRetry: _refresh,
        ),
      ),
    );
  }
}

class _NotificationSummaryCard extends StatelessWidget {
  final NotificationsResponse notifications;

  const _NotificationSummaryCard({required this.notifications});

  @override
  Widget build(BuildContext context) {
    final unread = notifications.unreadCount;
    final total = notifications.notifications.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.cardPrimaryStart, AppColors.cardPrimaryEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardPrimaryStart.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Inbox Overview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Stay on top of updates from your classes and admin.',
            style: TextStyle(
              color: Color(0xFFE0E7FF),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _NotificationPill(
                icon: Icons.mail_outline,
                text: '$total total',
              ),
              _NotificationPill(
                icon: Icons.mark_email_unread_outlined,
                text: '$unread unread',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _NotificationPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: Colors.white.withValues(alpha: 0.16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationItem item;
  final bool isProcessing;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.item,
    required this.isProcessing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor(item.type);
    final isUnread = !item.read;
    final cardColor =
        isUnread ? accent.withValues(alpha: 0.06) : AppColors.cardSurface;
    final borderColor =
        isUnread ? accent.withValues(alpha: 0.36) : AppColors.cardBorder;

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
            ),
            boxShadow: isUnread
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  color: accent.withValues(alpha: 0.14),
                ),
                child: Icon(_iconForType(item.type), color: accent, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontWeight:
                                  item.read ? FontWeight.w600 : FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isProcessing)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          _NotificationStateChip(
                            isRead: item.read,
                            accent: accent,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.message,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isUnread
                            ? AppColors.textPrimary.withValues(alpha: 0.82)
                            : AppColors.textSecondary,
                        fontWeight:
                            isUnread ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: AppColors.textSecondary.withValues(alpha: 0.9),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.createdAt,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (isUnread)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Tap to mark as viewed',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: accent,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _accentColor(String type) {
    switch (type.toLowerCase()) {
      case 'warning':
        return AppColors.warning;
      case 'error':
        return AppColors.error;
      case 'success':
        return AppColors.success;
      default:
        return AppColors.info;
    }
  }

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'error':
        return Icons.error_outline;
      case 'success':
        return Icons.check_circle_outline;
      default:
        return Icons.notifications_none_rounded;
    }
  }
}

class _NotificationStateChip extends StatelessWidget {
  final bool isRead;
  final Color accent;

  const _NotificationStateChip({required this.isRead, required this.accent});

  @override
  Widget build(BuildContext context) {
    final color = isRead ? AppColors.textSecondary : accent;
    final background =
        isRead ? AppColors.whiteColor : accent.withValues(alpha: 0.14);
    final borderColor =
        isRead ? AppColors.cardBorder : accent.withValues(alpha: 0.4);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRead
                ? Icons.visibility_outlined
                : Icons.mark_email_unread_outlined,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            isRead ? 'Viewed' : 'New',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationDetailSheet extends StatelessWidget {
  final NotificationItem item;

  const _NotificationDetailSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.createdAt,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                item.message,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationsEmptyState extends StatelessWidget {
  const _NotificationsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 36,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 10),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'You are all caught up for now.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _NotificationsErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 40, color: AppColors.error),
            const SizedBox(height: 12),
            const Text(
              'Unable to load notifications',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => onRetry(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
