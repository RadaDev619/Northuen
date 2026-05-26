import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../state/app_state.dart';
import '../widgets/status_chip.dart';
import 'product_menu_screen.dart';

class VendorListScreen extends StatefulWidget {
  const VendorListScreen({super.key});

  @override
  State<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends State<VendorListScreen> {
  final _search = TextEditingController();
  String _category = 'ALL';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().loadVendors();
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return RefreshIndicator(
      onRefresh: () =>
          app.loadVendors(query: _search.text, category: _category),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: NorthuenTheme.dark,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivering around Thimphu',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Food, shops, parcels, and COD convenience.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.delivery_dining_rounded,
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
              labelText: 'Search Northuen',
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
          Row(
            children: const [
              Expanded(
                child: _PromiseTile(
                  icon: Icons.payments_rounded,
                  label: 'COD only',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _PromiseTile(
                  icon: Icons.schedule_rounded,
                  label: 'Live status',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _PromiseTile(
                  icon: Icons.map_rounded,
                  label: 'Driver GPS',
                ),
              ),
            ],
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
            const Center(child: CircularProgressIndicator()),
          if (!app.loading && app.vendors.isEmpty)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: Text('No vendors match this search yet.')),
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
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: NorthuenTheme.gold.withValues(alpha: .16),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: vendor.imageUrl == null
                              ? const Icon(
                                  Icons.restaurant_menu_rounded,
                                  color: NorthuenTheme.dark,
                                )
                              : Image.network(
                                  vendor.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.storefront_rounded,
                                        color: NorthuenTheme.dark,
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
                                vendor.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              StatusChip(
                                vendor.open ? 'OPEN' : 'CLOSED',
                                color: vendor.open
                                    ? NorthuenTheme.success
                                    : Colors.grey,
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
    );
  }

  void _applyFilters() {
    context.read<AppState>().loadVendors(
      query: _search.text,
      category: _category,
    );
  }
}

class _PromiseTile extends StatelessWidget {
  const _PromiseTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
