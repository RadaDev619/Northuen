import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../models/order_model.dart';
import '../state/app_state.dart';
import '../widgets/money_text.dart';
import '../widgets/status_chip.dart';

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key, required this.order});

  final Order order;

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  StreamSubscription<Position>? _positionSubscription;
  LatLng? _driverLocation;
  GoogleMapController? _mapController;
  String? _locationMessage;
  bool _tracking = false;

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deliveryId = widget.order.delivery?.id;
    final pickup = const LatLng(27.4728, 89.6390);
    final dropoff = const LatLng(27.4850, 89.6250);
    final driver = _driverLocation ?? const LatLng(27.4782, 89.6320);
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              StatusChip(widget.order.status),
              const Spacer(),
              StatusChip(
                _tracking ? 'GPS LIVE' : 'GPS OFF',
                color: _tracking ? Colors.green : Colors.grey,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 260,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(target: driver, zoom: 13),
                onMapCreated: (controller) => _mapController = controller,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                markers: {
                  Marker(
                    markerId: const MarkerId('pickup'),
                    position: pickup,
                    infoWindow: const InfoWindow(title: 'Pickup'),
                  ),
                  Marker(
                    markerId: const MarkerId('driver'),
                    position: driver,
                    infoWindow: const InfoWindow(title: 'Runner'),
                  ),
                  Marker(
                    markerId: const MarkerId('dropoff'),
                    position: dropoff,
                    infoWindow: const InfoWindow(title: 'Dropoff'),
                  ),
                },
              ),
            ),
          ),
          if (_locationMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _locationMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.storefront_rounded),
              title: const Text('Pickup'),
              subtitle: Text(widget.order.pickupAddress),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.location_on_rounded),
              title: const Text('Dropoff'),
              subtitle: Text(widget.order.dropoffAddress),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.payments_rounded),
              title: const Text('Cash to collect'),
              trailing: MoneyText(
                widget.order.totalAmount,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (deliveryId != null) ...[
            _Action(
              label: 'Accept Delivery',
              icon: Icons.check_rounded,
              onPressed: () => context.read<AppState>().updateDelivery(
                deliveryId,
                'ACCEPTED',
              ),
            ),
            _Action(
              label: 'Picked Up',
              icon: Icons.shopping_bag_rounded,
              onPressed: () async {
                await context.read<AppState>().updateDelivery(
                  deliveryId,
                  'PICKED_UP',
                );
                await _startLiveTracking(deliveryId);
              },
            ),
            _Action(
              label: 'On The Way',
              icon: Icons.navigation_rounded,
              onPressed: () async {
                await context.read<AppState>().updateDelivery(
                  deliveryId,
                  'ON_THE_WAY',
                );
                await _startLiveTracking(deliveryId);
              },
            ),
            _Action(
              label: _tracking ? 'Stop Live GPS' : 'Start Live GPS',
              icon: _tracking
                  ? Icons.location_disabled_rounded
                  : Icons.my_location_rounded,
              onPressed: () => _tracking
                  ? _stopLiveTracking()
                  : _startLiveTracking(deliveryId),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                await _sendCurrentLocation(deliveryId);
                await _stopLiveTracking();
                if (context.mounted) {
                  await context.read<AppState>().completeDelivery(deliveryId);
                }
              },
              icon: const Icon(Icons.price_check_rounded),
              label: const Text('Delivered & Cash Collected'),
            ),
          ],
        ],
      ),
    );
  }

  Future<bool> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(
        () => _locationMessage =
            'Turn on phone location services to send live GPS.',
      );
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(
        () => _locationMessage =
            'Location permission is required for live delivery tracking.',
      );
      return false;
    }
    return true;
  }

  Future<void> _startLiveTracking(String deliveryId) async {
    if (!await _ensureLocationPermission()) return;
    if (!mounted) return;
    final appState = context.read<AppState>();
    await _positionSubscription?.cancel();
    setState(() {
      _tracking = true;
      _locationMessage = 'Live GPS tracking started.';
    });
    final settings = const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 8,
    );
    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: settings).listen(
          (position) async {
            final next = LatLng(position.latitude, position.longitude);
            setState(() => _driverLocation = next);
            _mapController?.animateCamera(CameraUpdate.newLatLng(next));
            await appState.sendLocation(
              deliveryId,
              position.latitude,
              position.longitude,
            );
          },
          onError: (error) {
            setState(() {
              _tracking = false;
              _locationMessage = 'GPS tracking stopped: $error';
            });
          },
        );
    await _sendCurrentLocation(deliveryId);
  }

  Future<void> _sendCurrentLocation(String deliveryId) async {
    if (!await _ensureLocationPermission()) return;
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
      ),
    );
    final next = LatLng(position.latitude, position.longitude);
    setState(() => _driverLocation = next);
    _mapController?.animateCamera(CameraUpdate.newLatLng(next));
    if (mounted) {
      await context.read<AppState>().sendLocation(
        deliveryId,
        position.latitude,
        position.longitude,
      );
    }
  }

  Future<void> _stopLiveTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    if (mounted) {
      setState(() {
        _tracking = false;
        _locationMessage = 'Live GPS tracking stopped.';
      });
    }
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    ),
  );
}
