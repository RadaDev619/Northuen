import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../models/order_model.dart';
import '../models/pickdrop_model.dart';
import '../state/app_state.dart';
import '../widgets/money_text.dart';
import '../widgets/northuen_ui.dart';
import '../widgets/status_chip.dart';
import 'order_tracking_screen.dart';
import 'pickdrop_tracking_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  String _filter = 'ALL';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final app = context.read<AppState>();
    await app.loadOrders();
    await app.loadPickDropOrders();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final regular = app.orders.where((order) {
      if (_filter == 'ALL') return true;
      if (_filter == 'PICK_DROP') return false;
      return order.orderType == _filter;
    }).toList();
    final pickDrop = _filter == 'ALL' || _filter == 'PICK_DROP'
        ? app.pickDropOrders
        : <PickDropOrder>[];
    final empty = regular.isEmpty && pickDrop.isEmpty;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        children: [
          Text('Your orders', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Track active deliveries and review previous orders.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: NorthuenTheme.muted),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'ALL', label: Text('All')),
                ButtonSegment(
                  value: 'FOOD',
                  label: Text('Food'),
                  icon: Icon(Icons.restaurant_rounded, size: 17),
                ),
                ButtonSegment(
                  value: 'SHOP',
                  label: Text('Shop'),
                  icon: Icon(Icons.storefront_rounded, size: 17),
                ),
                ButtonSegment(
                  value: 'PARCEL',
                  label: Text('Parcel'),
                  icon: Icon(Icons.inventory_2_outlined, size: 17),
                ),
                ButtonSegment(
                  value: 'PICK_DROP',
                  label: Text('Pick & Drop'),
                  icon: Icon(Icons.route_rounded, size: 17),
                ),
              ],
              selected: {_filter},
              onSelectionChanged: (value) =>
                  setState(() => _filter = value.first),
              showSelectedIcon: false,
            ),
          ),
          const SizedBox(height: 16),
          if (app.loading && empty)
            ...List.generate(
              3,
              (_) => const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: NorthuenSkeleton(height: 132),
              ),
            ),
          if (!app.loading && empty)
            const NorthuenEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No orders in this category',
              message: 'Your active and completed deliveries will appear here.',
            ),
          ...pickDrop.map(
            (order) => _PickDropOrderCard(
              order: order,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PickDropTrackingScreen(order: order),
                ),
              ),
            ),
          ),
          ...regular.map(
            (order) => _OrderCard(
              order: order,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OrderTrackingScreen(order: order),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _OrderCardShell(
      icon: switch (order.orderType) {
        'FOOD' => Icons.restaurant_rounded,
        'SHOP' => Icons.storefront_rounded,
        _ => Icons.inventory_2_outlined,
      },
      color: switch (order.orderType) {
        'FOOD' => NorthuenTheme.orange,
        'SHOP' => NorthuenTheme.teal,
        _ => NorthuenTheme.primary,
      },
      title: '${_label(order.orderType)} delivery',
      route: '${order.pickupAddress} → ${order.dropoffAddress}',
      date: order.createdAt,
      amount: order.totalAmount,
      status: order.status,
      paymentStatus: order.paymentStatus,
      onTap: onTap,
    );
  }

  String _label(String type) {
    return switch (type) {
      'FOOD' => 'Food',
      'SHOP' => 'Shop',
      'PARCEL' => 'Parcel',
      _ => type,
    };
  }
}

class _PickDropOrderCard extends StatelessWidget {
  const _PickDropOrderCard({required this.order, required this.onTap});

  final PickDropOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _OrderCardShell(
      icon: Icons.route_rounded,
      color: NorthuenTheme.primary,
      title: 'Pick & Drop',
      route: '${order.pickupAddress} → ${order.dropAddress}',
      date: order.createdAt,
      amount: order.estimatedPrice,
      status: order.status,
      paymentStatus: order.paymentStatus,
      onTap: onTap,
    );
  }
}

class _OrderCardShell extends StatelessWidget {
  const _OrderCardShell({
    required this.icon,
    required this.color,
    required this.title,
    required this.route,
    required this.date,
    required this.amount,
    required this.status,
    required this.paymentStatus,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String route;
  final DateTime date;
  final num amount;
  final String status;
  final String paymentStatus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            DateFormat('MMM d, yyyy • h:mm a').format(date),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    MoneyText(
                      amount,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  route,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: NorthuenTheme.muted,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    StatusChip(status),
                    const SizedBox(width: 7),
                    StatusChip(paymentStatus),
                    const Spacer(),
                    const Text(
                      'View details',
                      style: TextStyle(
                        color: NorthuenTheme.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: NorthuenTheme.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
