import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../state/app_state.dart';
import '../state/cart_state.dart';
import '../widgets/money_text.dart';
import 'order_tracking_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _address = TextEditingController(text: 'Changzamtog, Thimphu');
  final _notes = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          Text(
            'Delivery details',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _address,
                    decoration: const InputDecoration(
                      labelText: 'Delivery address',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notes,
                    decoration: const InputDecoration(
                      labelText: 'Delivery notes',
                      hintText: 'Landmark, floor, or handover instructions',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                    minLines: 2,
                    maxLines: 4,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Payment method', style: Theme.of(context).textTheme.titleLarge),
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
              subtitle: Text('Pay after your delivery is completed.'),
              trailing: Icon(
                Icons.radio_button_checked_rounded,
                color: NorthuenTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Order summary', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ...cart.lines.map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${line.quantity}× ${line.product.name}',
                            ),
                          ),
                          MoneyText(line.lineTotal),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 22),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Total COD',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      MoneyText(
                        cart.total,
                        style: const TextStyle(
                          color: NorthuenTheme.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: NorthuenTheme.border)),
          ),
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _place,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_outline_rounded),
            label: Text(_saving ? 'Placing order...' : 'Place COD order'),
          ),
        ),
      ),
    );
  }

  Future<void> _place() async {
    setState(() => _saving = true);
    final order = await context.read<AppState>().createShopOrder(
      context.read<CartState>(),
      _address.text,
      _notes.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: order)),
      (route) => route.isFirst,
    );
  }
}
