import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../state/cart_state.dart';
import 'cart_screen.dart';
import 'home_dashboard_screen.dart';
import 'order_history_screen.dart';
import 'notifications_screen.dart';
import 'pickdrop_request_screen.dart';
import 'profile_screen.dart';
import 'vendor_list_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartState>().lines.length;
    final pages = [
      HomeDashboardScreen(
        onPickDrop: () => setState(() => _index = 1),
        onFood: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const VendorListScreen())),
      ),
      const PickDropRequestScreen(),
      const OrderHistoryScreen(),
      const _WalletScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFD2AB50),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.near_me_rounded,
                size: 19,
                color: Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Northuen',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
            icon: Badge(
              label: Text('${context.watch<AppState>().unreadNotifications}'),
              isLabelVisible: context.watch<AppState>().unreadNotifications > 0,
              child: const Icon(Icons.notifications_rounded),
            ),
          ),
          IconButton(
            tooltip: 'Cart',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CartScreen())),
            icon: Badge(
              label: Text('$cartCount'),
              isLabelVisible: cartCount > 0,
              child: const Icon(Icons.shopping_bag_rounded),
            ),
          ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.route_rounded), label: 'Book'),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Wallet',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _WalletScreen extends StatefulWidget {
  const _WalletScreen();

  @override
  State<_WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<_WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppState>().loadWallet();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final wallet = app.wallet;
    final dateFormat = DateFormat('MMM d, h:mm a');
    return RefreshIndicator(
      onRefresh: () => context.read<AppState>().loadWallet(),
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            'Wallet',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Northuen Token Balance',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  wallet == null
                      ? 'Loading...'
                      : '${_formatAmount(wallet.tokenBalance)} ${wallet.currency}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 30,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Tokens are recharged manually by Northuen staff for the pilot.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Card(
            child: ListTile(
              leading: Icon(Icons.add_card_rounded),
              title: Text('Manual Recharge'),
              subtitle: Text(
                'Pilot top-ups are added from backend seed/admin records.',
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Card(
            child: ListTile(
              leading: Icon(Icons.payments_rounded),
              title: Text('Cash on Delivery'),
              subtitle: Text('Still available for deliveries and pick & drop.'),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Recent token activity',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          if (app.loading && wallet == null)
            const Center(child: CircularProgressIndicator()),
          if (!app.loading && wallet != null && wallet.transactions.isEmpty)
            const Card(
              child: ListTile(
                leading: Icon(Icons.receipt_long_rounded),
                title: Text('No token activity yet'),
                subtitle: Text('Manual recharge records will appear here.'),
              ),
            ),
          if (wallet != null)
            ...wallet.transactions.map(
              (transaction) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(
                        0xFFD2AB50,
                      ).withValues(alpha: .18),
                      child: const Icon(
                        Icons.toll_rounded,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                    title: Text(
                      transaction.note,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text(
                      '${transaction.reference} - ${dateFormat.format(transaction.createdAt)}',
                    ),
                    trailing: Text(
                      '+${_formatAmount(transaction.amount)} ${wallet.currency}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (app.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                app.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }

  String _formatAmount(num value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }
}
