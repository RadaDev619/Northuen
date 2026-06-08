import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../models/vendor_model.dart';
import '../state/app_state.dart';
import '../state/cart_state.dart';
import '../widgets/money_text.dart';
import 'cart_screen.dart';

const _grocerySage = NorthuenTheme.customerSecondary;
const _softSage = NorthuenTheme.customerSurfaceAlt;

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
    final cartCount = context.watch<CartState>().lines.length;
    final isGrocery = widget.vendor.category == 'SHOP';
    final productIcon = isGrocery
        ? Icons.shopping_basket_rounded
        : Icons.lunch_dining_rounded;

    return Scaffold(
      backgroundColor: isGrocery
          ? NorthuenTheme.customerBackground
          : Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.vendor.name),
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isGrocery ? _softSage : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: isGrocery
                  ? Border.all(color: NorthuenTheme.customerBorder)
                  : null,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: isGrocery
                      ? Colors.white
                      : NorthuenTheme.gold,
                  child: Icon(
                    isGrocery
                        ? Icons.local_grocery_store_rounded
                        : Icons.restaurant_rounded,
                    color: isGrocery ? _grocerySage : NorthuenTheme.dark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.vendor.address,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (app.loading && app.products.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
          if (!app.loading && app.products.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'No items available right now.',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ...app.products.map(
            (product) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        backgroundColor: isGrocery
                            ? _softSage
                            : NorthuenTheme.gold.withValues(alpha: .18),
                        child: Icon(
                          productIcon,
                          color: isGrocery ? _grocerySage : NorthuenTheme.dark,
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
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              product.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      _AddProductAction(
                        price: product.price,
                        onPressed: () async {
                          context.read<CartState>().add(widget.vendor, product);
                          await context.read<AppState>().addBackendCartItem(
                            product.id,
                            1,
                          );
                        },
                      ),
                    ],
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

class _AddProductAction extends StatelessWidget {
  const _AddProductAction({required this.price, required this.onPressed});

  final num price;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 56),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          MoneyText(price, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          IconButton.filledTonal(
            tooltip: 'Add',
            onPressed: onPressed,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}
