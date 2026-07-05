import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';

import '../core/config.dart';
import '../core/app_theme.dart';
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
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_serviceLabel(widget.order.orderType)} delivery'),
            Text(
              '#${widget.order.id.substring(0, 8).toUpperCase()}',
              style: const TextStyle(
                color: NorthuenTheme.muted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            bottom: 286,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: gDriver, zoom: 13),
              onMapCreated: (controller) => _mapController = controller,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              markers: {
                Marker(
                  markerId: const MarkerId('pickup'),
                  position: gPickup,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen,
                  ),
                  infoWindow: const InfoWindow(title: 'Pickup'),
                ),
                Marker(
                  markerId: const MarkerId('driver'),
                  position: gDriver,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure,
                  ),
                  infoWindow: const InfoWindow(title: 'Runner'),
                ),
                Marker(
                  markerId: const MarkerId('dropoff'),
                  position: gDropoff,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueOrange,
                  ),
                  infoWindow: const InfoWindow(title: 'Dropoff'),
                ),
              },
            ),
          ),
          Positioned(
            right: 14,
            bottom: 300,
            child: FloatingActionButton.small(
              heroTag: 'refresh-order-tracking',
              tooltip: 'Refresh location',
              backgroundColor: Colors.white,
              foregroundColor: NorthuenTheme.primary,
              onPressed: _refreshTracking,
              child: const Icon(Icons.refresh_rounded),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 296,
              decoration: const BoxDecoration(
                color: NorthuenTheme.background,
                border: Border(top: BorderSide(color: NorthuenTheme.border)),
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _statusTitle(widget.order.status),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _trackingMode,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      StatusChip(widget.order.status),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _OrderProgress(status: widget.order.status),
                  const SizedBox(height: 14),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          _AddressRow(
                            icon: Icons.storefront_rounded,
                            color: NorthuenTheme.success,
                            label: 'Pickup',
                            value: widget.order.pickupAddress,
                          ),
                          const Divider(height: 18),
                          _AddressRow(
                            icon: Icons.location_on_rounded,
                            color: NorthuenTheme.orange,
                            label: 'Deliver to',
                            value: widget.order.dropoffAddress,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: NorthuenTheme.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Cash on delivery',
                                style: TextStyle(
                                  color: NorthuenTheme.muted,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 3),
                              MoneyText(
                                widget.order.totalAmount,
                                style: const TextStyle(
                                  color: NorthuenTheme.primary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (widget.order.status == 'DELIVERED') ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _review,
                            icon: const Icon(Icons.star_rounded),
                            label: const Text('Rate order'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _serviceLabel(String type) => switch (type) {
    'FOOD' => 'Food',
    'SHOP' => 'Shop',
    'PARCEL' => 'Parcel',
    _ => 'Order',
  };

  String _statusTitle(String status) => switch (status) {
    'PLACED' => 'Order placed',
    'VENDOR_ACCEPTED' => 'Vendor accepted your order',
    'PREPARING' => 'Your order is being prepared',
    'READY_FOR_PICKUP' => 'Ready for runner pickup',
    'DRIVER_ASSIGNED' => 'Runner assigned',
    'ACCEPTED' => 'Runner accepted the delivery',
    'PICKED_UP' => 'Order picked up',
    'ON_THE_WAY' => 'On the way to you',
    'DELIVERED' => 'Delivery completed',
    'VENDOR_REJECTED' => 'Order rejected',
    'CANCELLED' => 'Order cancelled',
    _ => status.replaceAll('_', ' '),
  };

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

class _OrderProgress extends StatelessWidget {
  const _OrderProgress({required this.status});

  final String status;

  static const _steps = [
    'PLACED',
    'PREPARING',
    'DRIVER_ASSIGNED',
    'PICKED_UP',
    'ON_THE_WAY',
    'DELIVERED',
  ];

  @override
  Widget build(BuildContext context) {
    final normalized = switch (status) {
      'VENDOR_ACCEPTED' => 'PREPARING',
      'READY_FOR_PICKUP' || 'ACCEPTED' => 'DRIVER_ASSIGNED',
      _ => status,
    };
    final activeIndex = _steps.indexOf(normalized);
    final failed = status == 'CANCELLED' || status == 'VENDOR_REJECTED';
    return Row(
      children: List.generate(_steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          final stepIndex = index ~/ 2;
          return Expanded(
            child: Container(
              height: 3,
              color: !failed && stepIndex < activeIndex
                  ? NorthuenTheme.primary
                  : NorthuenTheme.border,
            ),
          );
        }
        final stepIndex = index ~/ 2;
        final reached = !failed && stepIndex <= activeIndex;
        return Container(
          width: 17,
          height: 17,
          decoration: BoxDecoration(
            color: reached ? NorthuenTheme.primary : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: reached ? NorthuenTheme.primary : NorthuenTheme.border,
              width: 2,
            ),
          ),
          child: reached
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 11)
              : null,
        );
      }),
    );
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 21),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
