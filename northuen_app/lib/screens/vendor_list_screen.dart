import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../state/app_state.dart';
import '../widgets/northuen_ui.dart';
import '../widgets/status_chip.dart';
import 'product_menu_screen.dart';

class VendorListScreen extends StatefulWidget {
  const VendorListScreen({super.key, this.initialCategory = 'ALL'});

  final String initialCategory;

  @override
  State<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends State<VendorListScreen> {
  final _search = TextEditingController();
  late String _category = widget.initialCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppState>().loadVendors(category: _category);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _category == 'FOOD'
              ? 'Food delivery'
              : _category == 'SHOP'
              ? 'Shops & grocery'
              : 'Explore vendors',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            app.loadVendors(query: _search.text, category: _category),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: NorthuenTheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _category == 'FOOD'
                              ? 'Good food, delivered'
                              : _category == 'SHOP'
                              ? 'Local shops at your fingertips'
                              : 'Everything nearby',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _category == 'FOOD'
                              ? 'Order from local kitchens and restaurants.'
                              : _category == 'SHOP'
                              ? 'Browse daily essentials from nearby stores.'
                              : 'Food and shopping with clear live status.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _category == 'SHOP'
                        ? Icons.shopping_bag_rounded
                        : Icons.delivery_dining_rounded,
                    color: Colors.white,
                    size: 46,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: _category == 'FOOD'
                    ? 'Search restaurants or dishes'
                    : _category == 'SHOP'
                    ? 'Search shops or products'
                    : 'Search vendors and products',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  tooltip: 'Search',
                  onPressed: _applyFilters,
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
              ),
              onSubmitted: (_) => _applyFilters(),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'ALL',
                  label: Text('All'),
                  icon: Icon(Icons.apps_rounded),
                ),
                ButtonSegment(
                  value: 'FOOD',
                  label: Text('Food'),
                  icon: Icon(Icons.restaurant_rounded),
                ),
                ButtonSegment(
                  value: 'SHOP',
                  label: Text('Shops'),
                  icon: Icon(Icons.store_rounded),
                ),
              ],
              selected: {_category},
              onSelectionChanged: (value) {
                setState(() => _category = value.first);
                _applyFilters();
              },
            ),
            const SizedBox(height: 14),
            if (app.loading && app.vendors.isEmpty)
              ...List.generate(
                3,
                (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: NorthuenSkeleton(height: 98),
                ),
              ),
            if (!app.loading && app.vendors.isEmpty)
              NorthuenEmptyState(
                icon: Icons.storefront_outlined,
                title: 'No vendors found',
                message: 'Try another search or category.',
                actionLabel: 'Clear filters',
                onAction: () {
                  _search.clear();
                  setState(() => _category = 'ALL');
                  _applyFilters();
                },
              ),
            ...app.vendors.map(
              (vendor) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProductMenuScreen(vendor: vendor),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              color: NorthuenTheme.orange.withValues(alpha: .1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: vendor.imageUrl == null
                                ? const Icon(
                                    Icons.restaurant_menu_rounded,
                                    color: NorthuenTheme.orange,
                                  )
                                : Image.network(
                                    vendor.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.storefront_rounded,
                                              color: NorthuenTheme.orange,
                                            ),
                                  ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vendor.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '${vendor.category} • ${vendor.address}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  vendor.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    StatusChip(
                                      vendor.open ? 'OPEN' : 'CLOSED',
                                      color: vendor.open
                                          ? NorthuenTheme.success
                                          : Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.schedule_rounded,
                                      size: 14,
                                      color: NorthuenTheme.muted,
                                    ),
                                    const Text(
                                      ' 25–40 min',
                                      style: TextStyle(
                                        color: NorthuenTheme.muted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _applyFilters() {
    context.read<AppState>().loadVendors(
      query: _search.text,
      category: _category,
    );
  }
}
