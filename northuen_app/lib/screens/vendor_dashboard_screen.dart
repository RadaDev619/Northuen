import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../core/app_theme.dart';
import '../widgets/northuen_ui.dart';
import '../widgets/money_text.dart';
import '../widgets/status_chip.dart';
import 'profile_screen.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  int _index = 0;
  final _shop = TextEditingController(text: 'Northuen Kitchen');
  final _category = TextEditingController(text: 'FOOD');
  final _description = TextEditingController(text: 'Bhutanese meals and tea');
  final _address = TextEditingController(text: 'Norzin Lam, Thimphu');
  final _product = TextEditingController(text: 'Ema Datshi Set');
  final _price = TextEditingController(text: '180');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().loadVendorProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [_manage(context), _orders(context), const ProfileScreen()];
    return Scaffold(
      appBar: AppBar(title: const Text('Vendor')),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() => _index = value);
          if (value == 1) context.read<AppState>().loadVendorOrders();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.storefront_rounded),
            label: 'Shop',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _manage(BuildContext context) {
    final app = context.watch<AppState>();
    return RefreshIndicator(
      onRefresh: app.loadVendorProducts,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Manage shop',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _shop,
            decoration: const InputDecoration(labelText: 'Shop name'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _category,
            decoration: const InputDecoration(labelText: 'Category'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _description,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _address,
            decoration: const InputDecoration(labelText: 'Address'),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _saveShop,
            icon: const Icon(Icons.save_rounded),
            label: const Text('Save Shop'),
          ),
          const SizedBox(height: 24),
          Text(
            'Products',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _product,
                  decoration: const InputDecoration(labelText: 'Product'),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 110,
                child: TextField(
                  controller: _price,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Nu.'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _saveProduct,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Product'),
          ),
          const SizedBox(height: 12),
          ...app.products.map(
            (product) => Card(
              child: ListTile(
                title: Text(product.name),
                subtitle: Text(product.description),
                trailing: MoneyText(product.price),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _orders(BuildContext context) {
    final app = context.watch<AppState>();
    final pending = app.orders
        .where((order) => order.status == 'PLACED')
        .length;
    final preparing = app.orders
        .where((order) => order.status == 'PREPARING')
        .length;
    final ready = app.orders
        .where((order) => order.status == 'READY_FOR_PICKUP')
        .length;
    return RefreshIndicator(
      onRefresh: app.loadVendorOrders,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order inbox',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Refresh',
                onPressed: app.loadVendorOrders,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.05,
            children: [
              NorthuenMetricCard(
                label: 'New',
                value: '$pending',
                icon: Icons.fiber_new_rounded,
                color: NorthuenTheme.orange,
              ),
              NorthuenMetricCard(
                label: 'Preparing',
                value: '$preparing',
                icon: Icons.soup_kitchen_outlined,
                color: NorthuenTheme.warning,
              ),
              NorthuenMetricCard(
                label: 'Ready',
                value: '$ready',
                icon: Icons.inventory_2_outlined,
                color: NorthuenTheme.success,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...app.orders.map(
            (order) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          StatusChip(order.status),
                          MoneyText(
                            order.totalAmount,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        order.dropoffAddress,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        order.items
                            .map(
                              (item) => '${item.quantity}x ${item.productName}',
                            )
                            .join(', '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.tonal(
                            onPressed: () =>
                                _setOrder(order.id, 'VENDOR_ACCEPTED'),
                            child: const Text('Accept'),
                          ),
                          OutlinedButton(
                            onPressed: () => _setOrder(order.id, 'PREPARING'),
                            child: const Text('Preparing'),
                          ),
                          OutlinedButton(
                            onPressed: () =>
                                _setOrder(order.id, 'READY_FOR_PICKUP'),
                            child: const Text('Ready'),
                          ),
                          TextButton(
                            onPressed: () =>
                                _setOrder(order.id, 'VENDOR_REJECTED'),
                            child: const Text('Reject'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!app.loading && app.orders.isEmpty)
            const NorthuenEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No vendor orders yet',
              message: 'New customer orders will appear in this inbox.',
            ),
        ],
      ),
    );
  }

  Future<void> _saveShop() async {
    await context.read<AppState>().saveVendor({
      'name': _shop.text,
      'category': _category.text,
      'description': _description.text,
      'address': _address.text,
      'open': true,
    });
  }

  Future<void> _saveProduct() async {
    await context.read<AppState>().saveProduct({
      'name': _product.text,
      'description': 'Freshly prepared',
      'price': num.tryParse(_price.text) ?? 0,
      'category': _category.text,
      'available': true,
    });
    if (mounted) context.read<AppState>().loadVendorProducts();
  }

  Future<void> _setOrder(String orderId, String status) async {
    await context.read<AppState>().updateOrderStatus(orderId, status);
    if (mounted) context.read<AppState>().loadVendorOrders();
  }
}
