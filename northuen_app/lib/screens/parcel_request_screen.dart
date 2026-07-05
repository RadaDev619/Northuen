import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../state/app_state.dart';
import 'order_tracking_screen.dart';

class ParcelRequestScreen extends StatefulWidget {
  const ParcelRequestScreen({super.key});

  @override
  State<ParcelRequestScreen> createState() => _ParcelRequestScreenState();
}

class _ParcelRequestScreenState extends State<ParcelRequestScreen> {
  final _pickup = TextEditingController(text: 'Clock Tower Square, Thimphu');
  final _dropoff = TextEditingController(text: 'Motithang, Thimphu');
  final _description = TextEditingController(text: 'Small parcel');
  final _notes = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _pickup.dispose();
    _dropoff.dispose();
    _description.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Send a parcel'),
            Text(
              'Standard local parcel delivery',
              style: TextStyle(
                color: NorthuenTheme.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: NorthuenTheme.teal,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.inventory_2_outlined, color: Colors.white, size: 38),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Simple parcel delivery',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Enter the route and package information. Pay cash when delivered.',
                        style: TextStyle(color: Colors.white70, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Delivery route', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.trip_origin_rounded,
                          size: 17,
                          color: NorthuenTheme.success,
                        ),
                        Container(
                          width: 2,
                          height: 57,
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          color: NorthuenTheme.border,
                        ),
                        const Icon(
                          Icons.location_on_rounded,
                          size: 20,
                          color: NorthuenTheme.orange,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      children: [
                        TextField(
                          controller: _pickup,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Pickup address',
                            hintText: 'Where should we collect the parcel?',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _dropoff,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Delivery address',
                            hintText: 'Where should we deliver it?',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Package details',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  TextField(
                    controller: _description,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Parcel description',
                      hintText: 'Documents, clothes, small package',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notes,
                    decoration: const InputDecoration(
                      labelText: 'Handover instructions',
                      hintText: 'Contact person, landmark, or special handling',
                      prefixIcon: Icon(Icons.notes_rounded),
                      alignLabelWithHint: true,
                    ),
                    minLines: 2,
                    maxLines: 4,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Card(
            child: ListTile(
              leading: Icon(
                Icons.payments_outlined,
                color: NorthuenTheme.success,
              ),
              title: Text(
                'Cash on Delivery',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                'The delivery payment is collected on completion.',
              ),
              trailing: Icon(
                Icons.check_circle_rounded,
                color: NorthuenTheme.success,
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
            onPressed: _saving ? null : _request,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.local_shipping_outlined),
            label: Text(
              _saving ? 'Creating delivery...' : 'Request parcel delivery',
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _request() async {
    if (_pickup.text.trim().isEmpty ||
        _dropoff.text.trim().isEmpty ||
        _description.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete the route and parcel details.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final order = await context.read<AppState>().createParcel(
        _pickup.text.trim(),
        _dropoff.text.trim(),
        _description.text.trim(),
        _notes.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: order)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
