import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../widgets/money_text.dart';
import '../widgets/status_chip.dart';
import '../core/app_theme.dart';
import 'profile_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _index = 0;
  final _notificationTitle = TextEditingController(text: 'Northuen update');
  final _notificationMessage = TextEditingController(
    text: 'Your runner has reached the pickup point.',
  );
  String _targetMode = 'ALL';
  String _targetRole = 'CUSTOMER';
  String? _targetUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().loadAdmin();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _dashboard(context),
      _notifications(context),
      const ProfileScreen(),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Admin')),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_rounded),
            label: 'Notify',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _notifications(BuildContext context) {
    final app = context.watch<AppState>();
    _targetUserId ??= app.users.isEmpty ? null : app.users.first.id;
    return RefreshIndicator(
      onRefresh: app.loadAdmin,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Send notification',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Minimal manual notifications for pilot operations. Order status updates are still sent automatically.',
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<String>(
                    selected: {_targetMode},
                    segments: const [
                      ButtonSegment(
                        value: 'ALL',
                        icon: Icon(Icons.groups_rounded),
                        label: Text('All'),
                      ),
                      ButtonSegment(
                        value: 'ROLE',
                        icon: Icon(Icons.badge_rounded),
                        label: Text('Role'),
                      ),
                      ButtonSegment(
                        value: 'USER',
                        icon: Icon(Icons.person_rounded),
                        label: Text('User'),
                      ),
                    ],
                    onSelectionChanged: (value) =>
                        setState(() => _targetMode = value.first),
                  ),
                  const SizedBox(height: 12),
                  if (_targetMode == 'ROLE')
                    DropdownButtonFormField<String>(
                      initialValue: _targetRole,
                      decoration: const InputDecoration(
                        labelText: 'Target role',
                      ),
                      items: const ['CUSTOMER', 'DRIVER', 'VENDOR', 'ADMIN']
                          .map(
                            (role) => DropdownMenuItem(
                              value: role,
                              child: Text(role),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _targetRole = value!),
                    ),
                  if (_targetMode == 'USER')
                    DropdownButtonFormField<String>(
                      initialValue: _targetUserId,
                      decoration: const InputDecoration(
                        labelText: 'Target user',
                      ),
                      items: app.users
                          .map(
                            (user) => DropdownMenuItem(
                              value: user.id,
                              child: Text('${user.fullName} (${user.role})'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _targetUserId = value),
                    ),
                  if (_targetMode != 'ALL') const SizedBox(height: 12),
                  TextField(
                    controller: _notificationTitle,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      prefixIcon: Icon(Icons.title_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notificationMessage,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      prefixIcon: Icon(Icons.message_rounded),
                    ),
                    minLines: 3,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: app.loading
                        ? null
                        : () => _sendNotification(context),
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Send notification'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Quick messages',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                [
                      _QuickNotifyChip(
                        label: 'Item reached',
                        title: 'Runner reached',
                        message: 'Your runner has reached the pickup point.',
                      ),
                      _QuickNotifyChip(
                        label: 'Cash reminder',
                        title: 'Cash payment reminder',
                        message: 'Please keep cash ready for your delivery.',
                      ),
                      _QuickNotifyChip(
                        label: 'Pilot update',
                        title: 'Northuen pilot update',
                        message:
                            'Thanks for testing Northuen. New runner features are live now.',
                      ),
                    ]
                    .map(
                      (chip) => ActionChip(
                        avatar: const Icon(Icons.bolt_rounded, size: 18),
                        label: Text(chip.label),
                        onPressed: () => setState(() {
                          _notificationTitle.text = chip.title;
                          _notificationMessage.text = chip.message;
                        }),
                      ),
                    )
                    .toList(),
          ),
          if (app.error != null) ...[
            const SizedBox(height: 12),
            Text(
              app.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _sendNotification(BuildContext context) async {
    final app = context.read<AppState>();
    if (_notificationTitle.text.trim().isEmpty ||
        _notificationMessage.text.trim().isEmpty) {
      return;
    }
    await app.sendAdminNotification(
      title: _notificationTitle.text.trim(),
      message: _notificationMessage.text.trim(),
      targetMode: _targetMode,
      role: _targetMode == 'ROLE' ? _targetRole : null,
      userId: _targetMode == 'USER' ? _targetUserId : null,
    );
    if (context.mounted && app.error == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Notification sent')));
    }
  }

  Widget _dashboard(BuildContext context) {
    final app = context.watch<AppState>();
    final report = app.cashReport;
    return RefreshIndicator(
      onRefresh: app.loadAdmin,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'COD cash tracking',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          if (report != null)
            GridView.count(
              crossAxisCount: MediaQuery.sizeOf(context).width > 650 ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.7,
              children: [
                _Metric(
                  label: 'Total COD collected',
                  amount: report.totalCollected,
                  icon: Icons.savings_rounded,
                ),
                _Metric(
                  label: 'Driver settlement due',
                  amount: report.pendingDriverSettlement,
                  icon: Icons.account_balance_wallet_rounded,
                ),
                _Metric(
                  label: 'Paid settlements',
                  amount: report.paidDriverSettlement,
                  icon: Icons.price_check_rounded,
                ),
                _Metric(
                  label: 'Pending payments',
                  amount: report.pendingPayments,
                  icon: Icons.pending_actions_rounded,
                ),
                _Metric(
                  label: 'Paid orders',
                  value: '${report.paidCount}',
                  icon: Icons.verified_rounded,
                ),
                _Metric(
                  label: 'Pending orders',
                  value: '${report.pendingCount}',
                  icon: Icons.hourglass_top_rounded,
                ),
              ],
            ),
          const SizedBox(height: 22),
          Text(
            'Driver cash',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          ...?report?.drivers.map(
            (row) => Card(
              child: ListTile(
                leading: const Icon(Icons.delivery_dining_rounded),
                title: Text(row.driverName),
                subtitle: Text('Pending cash: Nu. ${row.pending}'),
                trailing: MoneyText(row.collected),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'All orders',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          ...app.orders.map(
            (order) => Card(
              child: ListTile(
                leading: const Icon(Icons.receipt_long_rounded),
                title: Text(
                  order.dropoffAddress,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('${order.orderType} · ${order.paymentStatus}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StatusChip(order.status),
                    MoneyText(order.totalAmount),
                  ],
                ),
                onTap: () => _assign(context, order.id),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _assign(BuildContext context, String orderId) async {
    final app = context.read<AppState>();
    if (app.drivers.isEmpty) return;
    String selected = app.drivers.first.id;
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Assign driver'),
        content: DropdownButtonFormField(
          initialValue: selected,
          items: app.drivers
              .map(
                (driver) => DropdownMenuItem(
                  value: driver.id,
                  child: Text(driver.fullName),
                ),
              )
              .toList(),
          onChanged: (value) => selected = value!,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await app.assignDriver(orderId, selected);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }
}

class _QuickNotifyChip {
  const _QuickNotifyChip({
    required this.label,
    required this.title,
    required this.message,
  });

  final String label;
  final String title;
  final String message;
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.icon,
    this.amount,
    this.value,
  });

  final String label;
  final IconData icon;
  final num? amount;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: NorthuenTheme.primary),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            amount == null
                ? Text(
                    value ?? '0',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  )
                : MoneyText(
                    amount!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
