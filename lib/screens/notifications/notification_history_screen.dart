import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../home_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    NotificationService().unreadCount.addListener(_onNewNotification);
  }

  void _onNewNotification() {
    // A new notification was stored/received. Reload the list.
    _loadNotifications();
  }

  @override
  void dispose() {
    NotificationService().unreadCount.removeListener(_onNewNotification);
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final list = await NotificationService().getStoredNotifications();
    await NotificationService().markAllRead();
    if (mounted) {
      setState(() {
        _notifications = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: isDesktop
            ? null
            : Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
                  onPressed: () => HomeScreen.openDrawer(),
                ),
              ),
        automaticallyImplyLeading: !isDesktop,
        title: const Text('Notifications', style: AppTextStyles.headingM),
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: () async {
                final prefs = await _clearNotifications();
                if (mounted && prefs) {
                  setState(() => _notifications = []);
                }
              },
              child: Text(
                'Clear All',
                style: AppTextStyles.labelS.copyWith(color: AppColors.error),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : _notifications.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.notifications_off_rounded,
                  title: 'No notifications yet',
                  subtitle:
                      'You\'ll see new order alerts, order status updates, and low stock warnings here.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xxl),
                  itemCount: _notifications.length,
                  itemBuilder: (_, i) =>
                      _NotificationTile(notification: _notifications[i]),
                ),
    );
  }

  Future<bool> _clearNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('app_notifications');
      return true;
    } catch (_) {
      return false;
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;

  const _NotificationTile({required this.notification});

  Color get _iconColor {
    switch (notification.type) {
      case 'new_order':
        return AppColors.accent;
      case 'order_updated':
        return AppColors.info;
      case 'order_cancelled':
        return AppColors.error;
      case 'low_stock':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData get _icon {
    switch (notification.type) {
      case 'new_order':
        return Icons.receipt_rounded;
      case 'order_updated':
        return Icons.update_rounded;
      case 'order_cancelled':
        return Icons.cancel_rounded;
      case 'low_stock':
        return Icons.warning_amber_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        color: notification.isRead
            ? AppColors.surface
            : AppColors.surface.withValues(alpha: 0.85),
        border: Border.all(
          color: notification.isRead ? AppColors.border : _iconColor.withValues(alpha: 0.4),
          width: 0.5,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, color: _iconColor, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTextStyles.labelM,
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.body,
                    style: AppTextStyles.bodyM
                        .copyWith(color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeago.format(notification.receivedAt),
                    style: AppTextStyles.bodyS
                        .copyWith(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
