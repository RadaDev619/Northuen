import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../models/notification_model.dart';
import '../state/app_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      backgroundColor: NorthuenTheme.customerBackground,
      appBar: AppBar(title: const Text('Notifications')),
      body: RefreshIndicator(
        onRefresh: app.loadNotifications,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (app.loading && app.notifications.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
            if (!app.loading && app.notifications.isEmpty)
              const _EmptyNotifications(),
            ...app.notifications.map((item) => _NotificationCard(item: item)),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item});

  final AppNotification item;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('MMM d, h:mm a').format(item.createdAt);
    final unread = !item.read;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: unread
              ? () => context.read<AppState>().markNotificationRead(item.id)
              : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: unread
                      ? NorthuenTheme.customerSurfaceAlt
                      : const Color(0xFFF1F5F2),
                  child: Icon(
                    _iconFor(item.type),
                    color: unread
                        ? NorthuenTheme.customerPrimary
                        : NorthuenTheme.muted,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontWeight: unread
                                    ? FontWeight.w900
                                    : FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (unread)
                            Container(
                              width: 9,
                              height: 9,
                              decoration: const BoxDecoration(
                                color: NorthuenTheme.customerSecondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.message,
                        style: const TextStyle(color: Color(0xFF4B5563)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        date,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    return switch (type) {
      'ORDER_STATUS' => Icons.route_rounded,
      'PAYMENT' => Icons.payments_rounded,
      'ADMIN' => Icons.campaign_rounded,
      _ => Icons.notifications_rounded,
    };
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: NorthuenTheme.customerBorder),
      ),
      child: const Column(
        children: [
          Icon(Icons.notifications_none_rounded, size: 42),
          SizedBox(height: 10),
          Text(
            'No notifications yet',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          SizedBox(height: 4),
          Text(
            'Order updates and admin announcements will appear here.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
