import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../models/order_model.dart';
import '../models/pickdrop_model.dart';
import '../state/app_state.dart';
import '../state/cart_state.dart';
import '../widgets/money_text.dart';
import '../widgets/status_chip.dart';
import 'auth_screen.dart';
import 'cart_screen.dart';
import 'notifications_screen.dart';
import 'order_history_screen.dart';
import 'order_tracking_screen.dart';
import 'pickdrop_request_screen.dart';
import 'pickdrop_tracking_screen.dart';
import 'vendor_list_screen.dart';

const _serviceTeal = NorthuenTheme.customerPrimary;
const _grocerySage = NorthuenTheme.customerSecondary;
const _warmAmber = NorthuenTheme.customerAccent;
const _softTeal = Color(0xFFFFF7ED);
const _softSage = NorthuenTheme.customerSurfaceAlt;
const _softAmber = Color(0xFFFFF7E8);

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final app = context.read<AppState>();
      await app.loadNotifications();
      await app.loadOrders();
      await app.loadPickDropOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartState>().lines.length;
    final pages = [
      _CustomerStartScreen(
        onPickDrop: _openPickDrop,
        onGrocery: _openGrocery,
        onViewOrders: () => setState(() => _index = 1),
      ),
      const OrderHistoryScreen(),
      const _CustomerAccountScreen(),
    ];

    return Scaffold(
      backgroundColor: NorthuenTheme.customerBackground,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _softTeal,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.near_me_rounded,
                size: 19,
                color: _serviceTeal,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Northuen',
              style: TextStyle(fontWeight: FontWeight.w800),
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
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          navigationBarTheme: Theme.of(context).navigationBarTheme.copyWith(
            indicatorColor: _softTeal,
            backgroundColor: Colors.white,
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_rounded),
              label: 'Orders',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_rounded),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }

  void _openPickDrop() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const _PickDropBookingRoute()));
  }

  void _openGrocery() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const _GroceryRoute()));
  }
}

class _CustomerStartScreen extends StatelessWidget {
  const _CustomerStartScreen({
    required this.onPickDrop,
    required this.onGrocery,
    required this.onViewOrders,
  });

  final VoidCallback onPickDrop;
  final VoidCallback onGrocery;
  final VoidCallback onViewOrders;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final userName = app.user?.fullName ?? 'Customer';
    final recent = _recentActivities(context, app).take(3).toList();

    return RefreshIndicator(
      onRefresh: () async {
        await app.loadOrders();
        await app.loadPickDropOrders();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        children: [
          _CustomerHero(firstName: _firstName(userName)),
          const SizedBox(height: 16),
          _PrimaryServiceCard(
            icon: Icons.route_rounded,
            title: 'Pick & Drop',
            subtitle: 'Send parcels, documents, or small items.',
            buttonLabel: 'Post request',
            badgeLabel: 'Runner service',
            accent: _serviceTeal,
            background: Colors.white,
            onTap: onPickDrop,
          ),
          const SizedBox(height: 12),
          _PrimaryServiceCard(
            icon: Icons.local_grocery_store_rounded,
            title: 'Buy Grocery',
            subtitle: 'Order daily essentials from nearby stores.',
            buttonLabel: 'Shop groceries',
            badgeLabel: 'Store delivery',
            accent: _grocerySage,
            background: Colors.white,
            onTap: onGrocery,
          ),
          const SizedBox(height: 14),
          const _TrustStrip(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Recent orders',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              TextButton(
                onPressed: onViewOrders,
                child: const Text('View all'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (app.loading && recent.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
          if (!app.loading && recent.isEmpty)
            _EmptyRecentOrders(onPickDrop: onPickDrop, onGrocery: onGrocery),
          ...recent.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RecentOrderTile(item: item),
            ),
          ),
        ],
      ),
    );
  }

  List<_RecentActivity> _recentActivities(BuildContext context, AppState app) {
    final items = <_RecentActivity>[
      ...app.pickDropOrders.map(
        (order) => _RecentActivity.pickDrop(
          order,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PickDropTrackingScreen(order: order),
            ),
          ),
        ),
      ),
      ...app.orders.map(
        (order) => _RecentActivity.grocery(
          order,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OrderTrackingScreen(order: order),
            ),
          ),
        ),
      ),
    ];

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  static String _firstName(String value) => value.trim().split(' ').first;
}

class _CustomerHero extends StatelessWidget {
  const _CustomerHero({required this.firstName});

  final String firstName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _softSage,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: NorthuenTheme.customerBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .72),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 16,
                      color: _serviceTeal,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Thimphu',
                      style: TextStyle(
                        color: NorthuenTheme.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.near_me_rounded, color: _serviceTeal),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Kuzuzangpo, $firstName',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: NorthuenTheme.muted,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'What do you need today?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: NorthuenTheme.ink,
              fontWeight: FontWeight.w800,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(
                child: _HeroStat(
                  icon: Icons.route_rounded,
                  label: 'Pick & Drop',
                  color: _serviceTeal,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _HeroStat(
                  icon: Icons.local_grocery_store_rounded,
                  label: 'Grocery',
                  color: _grocerySage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: .18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryServiceCard extends StatelessWidget {
  const _PrimaryServiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.badgeLabel,
    required this.accent,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final String badgeLabel;
  final Color accent;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: background,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: accent, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: .10),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badgeLabel,
                            style: TextStyle(
                              color: accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          style: const TextStyle(
                            color: NorthuenTheme.ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 21,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: NorthuenTheme.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  onPressed: onTap,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(buttonLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrustStrip extends StatelessWidget {
  const _TrustStrip();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _TrustTile(
            icon: Icons.payments_rounded,
            label: 'COD',
            color: _grocerySage,
            background: _softSage,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _TrustTile(
            icon: Icons.schedule_rounded,
            label: 'Live status',
            color: _serviceTeal,
            background: _softTeal,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _TrustTile(
            icon: Icons.support_agent_rounded,
            label: 'Support',
            color: _warmAmber,
            background: _softAmber,
          ),
        ),
      ],
    );
  }
}

class _TrustTile extends StatelessWidget {
  const _TrustTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: .18)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: NorthuenTheme.ink,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentOrderTile extends StatelessWidget {
  const _RecentOrderTile({required this.item});

  final _RecentActivity item;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('MMM d, h:mm a').format(item.createdAt);
    return Card(
      child: ListTile(
        onTap: item.onTap,
        leading: CircleAvatar(
          backgroundColor: item.color.withValues(alpha: .14),
          child: Icon(item.icon, color: item.color),
        ),
        title: Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(date),
        trailing: _RecentOrderMeta(item: item),
      ),
    );
  }
}

class _RecentOrderMeta extends StatelessWidget {
  const _RecentOrderMeta({required this.item});

  final _RecentActivity item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 98,
      height: 48,
      child: FittedBox(
        alignment: Alignment.centerRight,
        fit: BoxFit.scaleDown,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusChip(item.status),
            const SizedBox(height: 4),
            MoneyText(item.amount),
          ],
        ),
      ),
    );
  }
}

class _EmptyRecentOrders extends StatelessWidget {
  const _EmptyRecentOrders({required this.onPickDrop, required this.onGrocery});

  final VoidCallback onPickDrop;
  final VoidCallback onGrocery;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _softTeal,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: _serviceTeal,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'No recent orders yet.',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPickDrop,
                    icon: const Icon(Icons.route_rounded),
                    label: const Text('Pick & Drop'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _grocerySage,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: onGrocery,
                    icon: const Icon(Icons.local_grocery_store_rounded),
                    label: const Text('Grocery'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerAccountScreen extends StatefulWidget {
  const _CustomerAccountScreen();

  @override
  State<_CustomerAccountScreen> createState() => _CustomerAccountScreenState();
}

class _CustomerAccountScreenState extends State<_CustomerAccountScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().loadWallet();
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final user = app.user!;
    final wallet = app.wallet;

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _softSage,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: NorthuenTheme.customerBorder),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white,
                child: Text(
                  user.fullName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: _serviceTeal,
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        color: NorthuenTheme.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.phone,
                      style: const TextStyle(
                        color: NorthuenTheme.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      user.email,
                      style: const TextStyle(color: NorthuenTheme.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _AccountTile(
          icon: Icons.account_balance_wallet_rounded,
          iconColor: _grocerySage,
          title: 'Wallet',
          subtitle: wallet == null
              ? 'Loading balance'
              : '${_formatAmount(wallet.tokenBalance)} ${wallet.currency}',
        ),
        const SizedBox(height: 10),
        _AccountTile(
          icon: Icons.notifications_rounded,
          iconColor: _serviceTeal,
          title: 'Notifications',
          subtitle: '${app.unreadNotifications} unread',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
        ),
        const SizedBox(height: 10),
        const _AccountTile(
          icon: Icons.payments_rounded,
          iconColor: _warmAmber,
          title: 'Payment',
          subtitle: 'Cash on delivery',
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: () async {
            await context.read<AppState>().logout();
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthScreen()),
                (_) => false,
              );
            }
          },
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Logout'),
        ),
      ],
    );
  }

  String _formatAmount(num value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        minVerticalPadding: 14,
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: .14),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(subtitle),
        trailing: onTap == null
            ? null
            : const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _PickDropBookingRoute extends StatelessWidget {
  const _PickDropBookingRoute();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: NorthuenTheme.customerBackground,
      appBar: _RouteAppBar(title: 'Pick & Drop'),
      body: PickDropRequestScreen(),
    );
  }
}

class _GroceryRoute extends StatelessWidget {
  const _GroceryRoute();

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartState>().lines.length;
    return Scaffold(
      backgroundColor: NorthuenTheme.customerBackground,
      appBar: AppBar(
        title: const Text('Buy Grocery'),
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
      body: const VendorListScreen(groceryOnly: true),
    );
  }
}

class _RouteAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _RouteAppBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AppBar(title: Text(title));
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _RecentActivity {
  _RecentActivity({
    required this.title,
    required this.status,
    required this.amount,
    required this.createdAt,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  factory _RecentActivity.pickDrop(
    PickDropOrder order, {
    required VoidCallback onTap,
  }) {
    return _RecentActivity(
      title: 'Pick & Drop',
      status: order.status,
      amount: order.estimatedPrice,
      createdAt: order.createdAt,
      icon: Icons.route_rounded,
      color: _serviceTeal,
      onTap: onTap,
    );
  }

  factory _RecentActivity.grocery(Order order, {required VoidCallback onTap}) {
    return _RecentActivity(
      title: order.orderType == 'SHOP'
          ? 'Grocery order'
          : '${order.orderType} order',
      status: order.status,
      amount: order.totalAmount,
      createdAt: order.createdAt,
      icon: Icons.local_grocery_store_rounded,
      color: _grocerySage,
      onTap: onTap,
    );
  }

  final String title;
  final String status;
  final num amount;
  final DateTime createdAt;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}
