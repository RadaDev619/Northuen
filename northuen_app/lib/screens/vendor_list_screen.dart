import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../state/app_state.dart';
import '../widgets/status_chip.dart';
import 'product_menu_screen.dart';

const _grocerySage = NorthuenTheme.customerSecondary;
const _trackingTeal = NorthuenTheme.customerPrimary;
const _warmAmber = NorthuenTheme.customerAccent;
const _softSage = NorthuenTheme.customerSurfaceAlt;
const _softTeal = Color(0xFFFFF7ED);
const _softAmber = Color(0xFFFFF7E8);

class VendorListScreen extends StatefulWidget {
  const VendorListScreen({super.key, this.groceryOnly = false});

  final bool groceryOnly;

  @override
  State<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends State<VendorListScreen> {
  final _search = TextEditingController();
  late String _category;

  @override
  void initState() {
    super.initState();
    _category = widget.groceryOnly ? 'SHOP' : 'ALL';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppState>().loadVendors(category: _category);
      }
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
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
              color: widget.groceryOnly ? _softSage : NorthuenTheme.dark,
              borderRadius: BorderRadius.circular(8),
              border: widget.groceryOnly
                  ? Border.all(color: NorthuenTheme.customerBorder)
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.groceryOnly
                            ? 'Grocery delivery'
                            : 'Delivering around Thimphu',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: widget.groceryOnly
                                  ? NorthuenTheme.ink
                                  : Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.groceryOnly
                            ? 'Daily essentials from nearby stores.'
                            : 'Food, shops, parcels, and COD convenience.',
                        style: TextStyle(
                          color: widget.groceryOnly
                              ? NorthuenTheme.muted
                              : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: widget.groceryOnly
                        ? Colors.white.withValues(alpha: .82)
                        : Colors.white.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    widget.groceryOnly
                        ? Icons.local_grocery_store_rounded
                        : Icons.delivery_dining_rounded,
                    color: widget.groceryOnly ? _grocerySage : Colors.white,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _search,
            decoration: InputDecoration(
              labelText: widget.groceryOnly
                  ? 'Search groceries or stores'
                  : 'Search Northuen',
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
            children: [
              Expanded(
                child: _PromiseTile(
                  icon: Icons.payments_rounded,
                  label: 'COD only',
                  color: _grocerySage,
                  background: _softSage,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PromiseTile(
                  icon: Icons.schedule_rounded,
                  label: 'Live status',
                  color: _trackingTeal,
                  background: _softTeal,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PromiseTile(
                  icon: Icons.map_rounded,
                  label: 'Driver GPS',
                  color: _warmAmber,
                  background: _softAmber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!widget.groceryOnly) ...[
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
          ],
          if (app.loading && app.vendors.isEmpty)
            const Center(child: CircularProgressIndicator()),
          if (!app.loading && app.vendors.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.storefront_rounded,
                        color: NorthuenTheme.muted,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No stores match this search yet.',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
                            color: widget.groceryOnly
                                ? _softSage
                                : NorthuenTheme.gold.withValues(alpha: .16),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: vendor.imageUrl == null
                              ? Icon(
                                  widget.groceryOnly
                                      ? Icons.storefront_rounded
                                      : Icons.restaurant_menu_rounded,
                                  color: widget.groceryOnly
                                      ? _grocerySage
                                      : NorthuenTheme.dark,
                                )
                              : Image.network(
                                  vendor.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.storefront_rounded,
                                        color: _grocerySage,
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
                              Row(
                                children: [
                                  StatusChip(
                                    vendor.open ? 'OPEN' : 'CLOSED',
                                    color: vendor.open
                                        ? NorthuenTheme.success
                                        : Colors.grey,
                                  ),
                                  if (widget.groceryOnly) ...[
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.shopping_basket_rounded,
                                      size: 16,
                                      color: _grocerySage,
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Grocery',
                                      style: TextStyle(
                                        color: NorthuenTheme.muted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
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
  const _PromiseTile({
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
      height: 72,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: .18)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
