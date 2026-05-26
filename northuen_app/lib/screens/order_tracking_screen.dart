import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';

import '../core/config.dart';
import '../models/order_model.dart';
import '../models/tracking_point_model.dart';
import '../services/realtime_tracking_service.dart';
import '../state/app_state.dart';
import '../widgets/money_text.dart';
import '../widgets/status_chip.dart';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key, required this.order});

  final Order order;

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final _realtime = RealtimeTrackingService();
  Timer? _pollingTimer;
  String _trackingMode = 'Connecting';
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startTracking();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _realtime.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pickup = const ll.LatLng(27.4728, 89.6390);
    final dropoff = const ll.LatLng(27.4850, 89.6250);
    final tracking = context.watch<AppState>().trackingPoints;
    final driver = tracking.isEmpty
        ? const ll.LatLng(27.4782, 89.6320)
        : ll.LatLng(
            tracking.first.latitude.toDouble(),
            tracking.first.longitude.toDouble(),
          );
    final gPickup = _g(pickup);
    final gDropoff = _g(dropoff);
    final gDriver = _g(driver);
    return Scaffold(
      appBar: AppBar(title: const Text('Order tracking')),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: gDriver, zoom: 13),
              onMapCreated: (controller) => _mapController = controller,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              markers: {
                Marker(
                  markerId: const MarkerId('pickup'),
                  position: gPickup,
                  infoWindow: const InfoWindow(title: 'Pickup'),
                ),
                Marker(
                  markerId: const MarkerId('driver'),
                  position: gDriver,
                  infoWindow: const InfoWindow(title: 'Runner'),
                ),
                Marker(
                  markerId: const MarkerId('dropoff'),
                  position: gDropoff,
                  infoWindow: const InfoWindow(title: 'Dropoff'),
                ),
              },
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    StatusChip(widget.order.status),
                    StatusChip(widget.order.paymentStatus),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      AppConfig.hasSupabaseRealtime
                          ? Icons.sensors_rounded
                          : Icons.refresh_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _trackingMode,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    Text(
                      tracking.isEmpty
                          ? 'No GPS yet'
                          : '${tracking.length} updates',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.order.dropoffAddress,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Pay Cash on Delivery'),
                    MoneyText(
                      widget.order.totalAmount,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _refreshTracking,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Refresh'),
                      ),
                    ),
                    if (widget.order.status == 'DELIVERED') ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _review,
                          icon: const Icon(Icons.star_rounded),
                          label: const Text('Rate'),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startTracking() async {
    await _refreshTracking();
    final deliveryId = widget.order.delivery?.id;
    if (deliveryId == null) {
      setState(() => _trackingMode = 'Waiting for driver assignment');
      return;
    }
    if (AppConfig.hasSupabaseRealtime) {
      await _realtime.subscribe(
        deliveryId: deliveryId,
        onPoint: (TrackingPoint point) {
          if (mounted) {
            context.read<AppState>().addTrackingPoint(point);
            _mapController?.animateCamera(
              CameraUpdate.newLatLng(
                LatLng(point.latitude.toDouble(), point.longitude.toDouble()),
              ),
            );
          }
        },
      );
      setState(() => _trackingMode = 'Live via Supabase Realtime');
    } else {
      _pollingTimer?.cancel();
      _pollingTimer = Timer.periodic(
        const Duration(seconds: 8),
        (_) => _refreshTracking(),
      );
      setState(() => _trackingMode = 'Live fallback: polling every 8s');
    }
  }

  LatLng _g(ll.LatLng point) => LatLng(point.latitude, point.longitude);

  Future<void> _refreshTracking() async {
    await context.read<AppState>().loadTracking(widget.order.id);
  }

  Future<void> _review() async {
    var vendorRating = 5;
    var driverRating = 5;
    final comment = TextEditingController();
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rate delivery'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField(
              initialValue: vendorRating,
              decoration: const InputDecoration(labelText: 'Vendor'),
              items: [1, 2, 3, 4, 5]
                  .map(
                    (v) => DropdownMenuItem(value: v, child: Text('$v stars')),
                  )
                  .toList(),
              onChanged: (value) => vendorRating = value!,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField(
              initialValue: driverRating,
              decoration: const InputDecoration(labelText: 'Driver'),
              items: [1, 2, 3, 4, 5]
                  .map(
                    (v) => DropdownMenuItem(value: v, child: Text('$v stars')),
                  )
                  .toList(),
              onChanged: (value) => driverRating = value!,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: comment,
              decoration: const InputDecoration(labelText: 'Comment'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await context.read<AppState>().reviewOrder(
                widget.order.id,
                vendorRating,
                driverRating,
                comment.text,
              );
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
