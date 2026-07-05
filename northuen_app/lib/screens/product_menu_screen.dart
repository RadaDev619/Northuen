import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../models/vendor_model.dart';
import '../state/app_state.dart';
import '../state/cart_state.dart';
import '../widgets/money_text.dart';
import '../widgets/northuen_ui.dart';
import '../widgets/status_chip.dart';
import 'cart_screen.dart';

class ProductMenuScreen extends StatefulWidget {
  const ProductMenuScreen({super.key, required this.vendor});
  final Vendor vendor;

  @override
  State<ProductMenuScreen> createState() => _ProductMenuScreenState();
}

class _ProductMenuScreenState extends State<ProductMenuScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().loadProducts(widget.vendor.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cart = context.watch<CartState>();
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 210,
            backgroundColor: NorthuenTheme.primaryDark,
            foregroundColor: Colors.white,
            title: Text(widget.vendor.name),
            flexibleSpace: FlexibleSpaceBar(
              background: _VendorHero(vendor: widget.vendor),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              cart.lines.isEmpty ? 30 : 100,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  children: [
                    StatusChip(
                      widget.vendor.open ? 'OPEN' : 'CLOSED',
                      color: widget.vendor.open
                          ? NorthuenTheme.success
                          : NorthuenTheme.muted,
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.star_rounded,
                      color: NorthuenTheme.warning,
                      size: 18,
                    ),
                    const Text(
                      ' 4.8',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.schedule_rounded,
                      size: 17,
                      color: NorthuenTheme.muted,
                    ),
                    const Text(
                      ' 25–40 min',
                      style: TextStyle(
                        color: NorthuenTheme.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const NorthuenSectionHeader(
                  title: 'Menu',
                  subtitle: 'Fresh items available for delivery',
                ),
                const SizedBox(height: 12),
                if (app.loading && app.products.isEmpty)
                  ...List.generate(
                    3,
                    (_) => const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: NorthuenSkeleton(height: 112),
                    ),
                  ),
                if (!app.loading && app.products.isEmpty)
                  const NorthuenEmptyState(
                    icon: Icons.restaurant_menu_rounded,
                    title: 'No products available',
                    message: 'This vendor has not listed any available items.',
                  ),
                ...app.products.map(
                  (product) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 82,
                              height: 82,
                              decoration: BoxDecoration(
                                color: NorthuenTheme.orange.withValues(
                                  alpha: .08,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: product.imageUrl == null
                                  ? Icon(
                                      widget.vendor.category == 'SHOP'
                                          ? Icons.shopping_bag_outlined
                                          : Icons.lunch_dining_rounded,
                                      color: widget.vendor.category == 'SHOP'
                                          ? NorthuenTheme.teal
                                          : NorthuenTheme.orange,
                                      size: 34,
                                    )
                                  : Image.network(
                                      product.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Icon(
                                        widget.vendor.category == 'SHOP'
                                            ? Icons.shopping_bag_outlined
                                            : Icons.lunch_dining_rounded,
                                        color: widget.vendor.category == 'SHOP'
                                            ? NorthuenTheme.teal
                                            : NorthuenTheme.orange,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  if (!product.available) ...[
                                    const Text(
                                      'Currently unavailable',
                                      style: TextStyle(
                                        color: NorthuenTheme.error,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                  ],
                                  Text(
                                    product.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      MoneyText(
                                        product.price,
                                        style: const TextStyle(
                                          color: NorthuenTheme.primary,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const Spacer(),
                                      IconButton.filled(
                                        tooltip: 'Add to cart',
                                        onPressed: !product.available
                                            ? null
                                            : () async {
                                                context.read<CartState>().add(
                                                  widget.vendor,
                                                  product,
                                                );
                                                await context
                                                    .read<AppState>()
                                                    .addBackendCartItem(
                                                      product.id,
                                                      1,
                                                    );
                                              },
                                        icon: const Icon(Icons.add_rounded),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: cart.lines.isEmpty
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: NorthuenTheme.border)),
                ),
                child: FilledButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const CartScreen())),
                  child: Row(
                    children: [
                      Text('${cart.lines.length} items'),
                      const Spacer(),
                      const Text('View cart'),
                      const SizedBox(width: 8),
                      MoneyText(
                        cart.total,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _VendorHero extends StatelessWidget {
  const _VendorHero({required this.vendor});
  final Vendor vendor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (vendor.imageUrl != null)
          Image.network(
            vendor.imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        Container(color: NorthuenTheme.primaryDark.withValues(alpha: .72)),
        Positioned(
          left: 18,
          right: 18,
          bottom: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vendor.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                vendor.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      vendor.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
