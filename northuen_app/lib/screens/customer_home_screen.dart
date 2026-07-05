import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../state/cart_state.dart';
import '../core/app_theme.dart';
import '../widgets/northuen_ui.dart';
import 'cart_screen.dart';
import 'home_dashboard_screen.dart';
import 'order_history_screen.dart';
import 'notifications_screen.dart';
import 'parcel_request_screen.dart';
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
        onPickDrop: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PickDropRequestScreen()),
        ),
        onFood: () => _openVendors('FOOD'),
        onShop: () => _openVendors('SHOP'),
        onParcel: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ParcelRequestScreen())),
      ),
      const OrderHistoryScreen(),
      const _WalletScreen(),
      const NotificationsScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            NorthuenBrandMark(size: 34),
            SizedBox(width: 10),
            Text('Northuen', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        actions: [
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
          NavigationDestination(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Wallet',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_rounded),
            label: 'Updates',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _openVendors(String category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VendorListScreen(initialCategory: category),
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
              color: NorthuenTheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Available token balance',
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
                  'Pilot recharge records are managed by Northuen operations.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(
                child: _WalletInfoCard(
                  icon: Icons.add_card_rounded,
                  title: 'Recharge',
                  subtitle: 'Manual pilot top-up',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _WalletInfoCard(
                  icon: Icons.payments_outlined,
                  title: 'COD',
                  subtitle: 'Pay on delivery',
                ),
              ),
            ],
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
            const NorthuenEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No token activity',
              message: 'Recharge and wallet records will appear here.',
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

class _WalletInfoCard extends StatelessWidget {
  const _WalletInfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: NorthuenTheme.teal),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
