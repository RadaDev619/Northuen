import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../state/app_state.dart';
import '../widgets/money_text.dart';
import '../widgets/status_chip.dart';
import 'order_tracking_screen.dart';
import 'pickdrop_tracking_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppState>()
          ..loadOrders()
          ..loadPickDropOrders();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final dateFormat = DateFormat('MMM d, h:mm a');
    return RefreshIndicator(
      onRefresh: () async {
        await app.loadOrders();
        await app.loadPickDropOrders();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Order history',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          ...app.pickDropOrders.map(
            (order) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: ListTile(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PickDropTrackingScreen(order: order),
                    ),
                  ),
                  title: const Text(
                    'Pick & Drop',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(dateFormat.format(order.createdAt)),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFF7ED),
                    child: Icon(
                      Icons.route_rounded,
                      color: NorthuenTheme.customerPrimary,
                    ),
                  ),
                  trailing: _OrderMeta(
                    status: order.status,
                    amount: order.estimatedPrice,
                  ),
                ),
              ),
            ),
          ),
          ...app.orders.map(
            (order) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: ListTile(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OrderTrackingScreen(order: order),
                    ),
                  ),
                  title: Text(
                    '${order.orderType} order',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(dateFormat.format(order.createdAt)),
                  leading: const CircleAvatar(
                    backgroundColor: NorthuenTheme.customerSurfaceAlt,
                    child: Icon(
                      Icons.receipt_long_rounded,
                      color: NorthuenTheme.customerSecondary,
                    ),
                  ),
                  trailing: _OrderMeta(
                    status: order.status,
                    amount: order.totalAmount,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderMeta extends StatelessWidget {
  const _OrderMeta({required this.status, required this.amount});

  final String status;
  final num amount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 98,
      height: 48,
      child: FittedBox(
        alignment: Alignment.centerRight,
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            StatusChip(status),
            const SizedBox(height: 4),
            MoneyText(amount),
          ],
        ),
      ),
    );
  }
}
