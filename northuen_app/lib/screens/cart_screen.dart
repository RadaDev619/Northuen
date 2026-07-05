import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../state/cart_state.dart';
import '../widgets/money_text.dart';
import '../widgets/northuen_ui.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Your cart')),
      body: cart.lines.isEmpty
          ? const NorthuenEmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'Your cart is empty',
              message: 'Browse nearby vendors and add something you like.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              children: [
                if (cart.vendor != null) ...[
                  Text(
                    cart.vendor!.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cart.vendor!.address,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 14),
                ],
                ...cart.lines.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: NorthuenTheme.orange.withValues(
                                  alpha: .08,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.fastfood_rounded,
                                color: NorthuenTheme.orange,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    line.product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Quantity ${line.quantity}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                MoneyText(
                                  line.lineTotal,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Remove item',
                                  onPressed: () => cart.remove(line.product.id),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: NorthuenTheme.error,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _TotalRow('Subtotal', cart.subtotal),
                        _TotalRow('Delivery fee', cart.deliveryFee),
                        const Divider(height: 22),
                        _TotalRow('Total', cart.total, bold: true),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.payments_outlined,
                      color: NorthuenTheme.success,
                    ),
                    title: Text(
                      'Cash on Delivery',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text('Pay the runner after your order arrives.'),
                    trailing: Icon(
                      Icons.check_circle_rounded,
                      color: NorthuenTheme.success,
                    ),
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
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Continue to checkout'),
                ),
              ),
            ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow(this.label, this.amount, {this.bold = false});
  final String label;
  final num amount;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: bold ? NorthuenTheme.ink : NorthuenTheme.muted,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
          MoneyText(
            amount,
            style: TextStyle(
              fontSize: bold ? 18 : 14,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
