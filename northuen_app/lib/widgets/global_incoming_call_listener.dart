import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../models/notification_model.dart';
import '../models/pickdrop_model.dart';
import '../screens/notifications_screen.dart';
import '../screens/pickdrop_call_screen.dart';
import '../state/app_state.dart';

class GlobalIncomingCallListener extends StatefulWidget {
  const GlobalIncomingCallListener({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<GlobalIncomingCallListener> createState() =>
      _GlobalIncomingCallListenerState();
}

class _GlobalIncomingCallListenerState
    extends State<GlobalIncomingCallListener> {
  Timer? _poller;
  Timer? _notificationPoller;
  bool _dialogOpen = false;
  String? _handledCallId;
  bool _notificationsPrimed = false;
  AppNotification? _banner;
  final Set<String> _seenNotificationIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _poller?.cancel();
    _notificationPoller?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_banner != null)
          Positioned(
            left: 14,
            right: 14,
            top: MediaQuery.of(context).padding.top + 10,
            child: AnimatedSlide(
              offset: Offset.zero,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: 1,
                duration: const Duration(milliseconds: 180),
                child: _InAppNotificationBanner(
                  notification: _banner!,
                  onClose: () => setState(() => _banner = null),
                  onTap: _openNotifications,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _start() {
    _poller?.cancel();
    _notificationPoller?.cancel();
    _poller = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _checkIncomingCall(),
    );
    _notificationPoller = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkNotifications(),
    );
    unawaited(_checkIncomingCall());
    unawaited(_checkNotifications());
  }

  Future<void> _checkIncomingCall() async {
    if (!mounted || _dialogOpen) return;
    final app = context.read<AppState>();
    if (!app.authenticated) return;
    final incoming = await app.loadIncomingPickDropCall();
    if (!mounted ||
        incoming == null ||
        incoming.call.id == _handledCallId ||
        incoming.call.status != 'RINGING') {
      return;
    }
    _dialogOpen = true;
    _handledCallId = incoming.call.id;
    final dialogContext = widget.navigatorKey.currentContext;
    if (dialogContext == null) {
      _dialogOpen = false;
      return;
    }
    await showDialog<void>(
      // The navigator key supplies the live root context after the async poll.
      // ignore: use_build_context_synchronously
      context: dialogContext,
      barrierDismissible: false,
      builder: (dialogContext) => _IncomingCallDialog(
        incoming: incoming,
        onDecline: () async {
          await app.endPickDropCall(incoming.call.id);
          if (dialogContext.mounted) Navigator.of(dialogContext).pop();
        },
        onAnswer: () {
          Navigator.of(dialogContext).pop();
          widget.navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => PickDropCallScreen(
                order: incoming.order,
                initialCall: incoming.call,
                startOutgoing: false,
              ),
            ),
          );
        },
      ),
    );
    _dialogOpen = false;
  }

  Future<void> _checkNotifications() async {
    if (!mounted) return;
    final app = context.read<AppState>();
    if (!app.authenticated) {
      _notificationsPrimed = false;
      _seenNotificationIds.clear();
      if (_banner != null) setState(() => _banner = null);
      return;
    }
    final items = await app.refreshNotificationsQuietly();
    if (!mounted) return;
    final unread = items.where((item) => !item.read).toList();
    if (!_notificationsPrimed) {
      _seenNotificationIds
        ..clear()
        ..addAll(unread.map((item) => item.id));
      _notificationsPrimed = true;
      return;
    }
    final fresh = unread
        .where((item) => !_seenNotificationIds.contains(item.id))
        .toList();
    if (fresh.isEmpty) return;
    final latest = fresh.first;
    _seenNotificationIds.addAll(fresh.map((item) => item.id));
    setState(() => _banner = latest);
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted || _banner?.id != latest.id) return;
      setState(() => _banner = null);
    });
  }

  void _openNotifications() {
    final notification = _banner;
    setState(() => _banner = null);
    if (notification != null && !notification.read) {
      unawaited(context.read<AppState>().markNotificationRead(notification.id));
    }
    widget.navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }
}

class _InAppNotificationBanner extends StatelessWidget {
  const _InAppNotificationBanner({
    required this.notification,
    required this.onClose,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onClose;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .18),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _colorFor(notification.type).withValues(alpha: .14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconFor(notification.type),
                  color: _colorFor(notification.type),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      notification.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: NorthuenTheme.dark,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: NorthuenTheme.muted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Dismiss',
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String? type) {
    return switch (type) {
      'ORDER_STATUS' => Icons.route_rounded,
      'PAYMENT' => Icons.payments_rounded,
      'ADMIN' => Icons.campaign_rounded,
      _ => Icons.notifications_rounded,
    };
  }

  Color _colorFor(String? type) {
    return switch (type) {
      'ORDER_STATUS' => const Color(0xFF2563EB),
      'PAYMENT' => NorthuenTheme.success,
      'ADMIN' => NorthuenTheme.gold,
      _ => NorthuenTheme.dark,
    };
  }
}

class _IncomingCallDialog extends StatelessWidget {
  const _IncomingCallDialog({
    required this.incoming,
    required this.onAnswer,
    required this.onDecline,
  });

  final IncomingPickDropCall incoming;
  final VoidCallback onAnswer;
  final Future<void> Function() onDecline;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(22),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF101418),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .28),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 44,
              backgroundColor: NorthuenTheme.gold,
              child: Text(
                incoming.call.callerName.characters.first.toUpperCase(),
                style: const TextStyle(
                  color: NorthuenTheme.dark,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              incoming.call.callerName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Incoming Northuen call',
              style: TextStyle(
                color: Color(0xFFD1D5DB),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 26),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CallAction(
                  label: 'Decline',
                  icon: Icons.call_end_rounded,
                  color: NorthuenTheme.error,
                  onPressed: onDecline,
                ),
                const SizedBox(width: 42),
                _CallAction(
                  label: 'Answer',
                  icon: Icons.call_rounded,
                  color: NorthuenTheme.success,
                  onPressed: () async => onAnswer(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CallAction extends StatelessWidget {
  const _CallAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filled(
          style: IconButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            fixedSize: const Size(66, 66),
          ),
          onPressed: onPressed,
          icon: Icon(icon, size: 30),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
