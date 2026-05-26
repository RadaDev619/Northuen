import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/pickdrop_model.dart';
import '../services/geoapify_routing_service.dart';
import '../state/app_state.dart';
import '../widgets/money_text.dart';
import 'pickdrop_tracking_screen.dart';

class PickDropRequestScreen extends StatefulWidget {
  const PickDropRequestScreen({super.key});

  @override
  State<PickDropRequestScreen> createState() => _PickDropRequestScreenState();
}

class _PickDropRequestScreenState extends State<PickDropRequestScreen> {
  final _pickupAddress = TextEditingController(
    text: 'Clock Tower Square, Thimphu',
  );
  final _dropAddress = TextEditingController(text: 'Motithang, Thimphu');
  final _itemType = TextEditingController(text: 'Small parcel');
  final _itemDescription = TextEditingController(
    text: 'Documents or small package',
  );
  gmaps.GoogleMapController? _mapController;
  final _routing = GeoapifyRoutingService();
  LatLng _pickup = const LatLng(27.4728, 89.6390);
  LatLng _drop = const LatLng(27.4850, 89.6250);
  List<LatLng> _routePoints = const [];
  String _mode = 'PICKUP';
  PickDropFare? _fare;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _estimate());
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: gmaps.GoogleMap(
            initialCameraPosition: gmaps.CameraPosition(
              target: _g(_pickup),
              zoom: 13,
            ),
            onMapCreated: (controller) => _mapController = controller,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onTap: (point) {
              final next = LatLng(point.latitude, point.longitude);
              setState(() {
                if (_mode == 'PICKUP') {
                  _pickup = next;
                  _pickupAddress.text =
                      'Pinned pickup (${next.latitude.toStringAsFixed(5)}, ${next.longitude.toStringAsFixed(5)})';
                } else {
                  _drop = next;
                  _dropAddress.text =
                      'Pinned drop (${next.latitude.toStringAsFixed(5)}, ${next.longitude.toStringAsFixed(5)})';
                }
              });
              _estimate();
            },
            polylines: {
              gmaps.Polyline(
                polylineId: const gmaps.PolylineId('route'),
                points: (_routePoints.isEmpty ? [_pickup, _drop] : _routePoints)
                    .map(_g)
                    .toList(),
                width: 5,
                color: Theme.of(context).colorScheme.primary,
              ),
            },
            markers: {
              gmaps.Marker(
                markerId: const gmaps.MarkerId('pickup'),
                position: _g(_pickup),
                infoWindow: const gmaps.InfoWindow(title: 'Pickup'),
              ),
              gmaps.Marker(
                markerId: const gmaps.MarkerId('drop'),
                position: _g(_drop),
                infoWindow: const gmaps.InfoWindow(title: 'Drop'),
              ),
            },
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          top: 12,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'PICKUP',
                        icon: Icon(Icons.my_location_rounded),
                        label: Text('Pickup'),
                      ),
                      ButtonSegment(
                        value: 'DROP',
                        icon: Icon(Icons.location_on_rounded),
                        label: Text('Drop'),
                      ),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (value) =>
                        setState(() => _mode = value.first),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Use GPS',
                  onPressed: _useCurrentLocation,
                  icon: const Icon(Icons.gps_fixed_rounded),
                ),
              ],
            ),
          ),
        ),
        DraggableScrollableSheet(
          initialChildSize: .48,
          minChildSize: .34,
          maxChildSize: .78,
          builder: (context, controller) => Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF8F6F1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8D1C4),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Book a runner',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Select pickup and drop. Pay after delivery.',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _pickupAddress,
                  decoration: const InputDecoration(
                    labelText: 'Pickup location',
                    prefixIcon: Icon(Icons.my_location_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _dropAddress,
                  decoration: const InputDecoration(
                    labelText: 'Drop-off location',
                    prefixIcon: Icon(Icons.location_on_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _VehicleOption(
                        icon: Icons.two_wheeler_rounded,
                        title: 'Bike',
                        selected: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _VehicleOption(
                        icon: Icons.directions_car_rounded,
                        title: 'Car',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _VehicleOption(
                        icon: Icons.airport_shuttle_rounded,
                        title: 'Van',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _itemType,
                  decoration: const InputDecoration(
                    labelText: 'Item type',
                    prefixIcon: Icon(Icons.inventory_2_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _itemDescription,
                  decoration: const InputDecoration(labelText: 'Item details'),
                  minLines: 2,
                  maxLines: 3,
                ),
                const SizedBox(height: 14),
                _FareCard(fare: _fare, onRefresh: _estimate),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _saving || _fare == null ? null : _confirm,
                  icon: const Icon(Icons.check_circle_rounded),
                  label: Text(
                    _saving ? 'Finding runner...' : 'Confirm Booking',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _estimate() async {
    final fare = await context.read<AppState>().estimatePickDropFare(
      pickupLat: _pickup.latitude,
      pickupLng: _pickup.longitude,
      dropLat: _drop.latitude,
      dropLng: _drop.longitude,
    );
    final route = await _routing.route(from: _pickup, to: _drop);
    if (mounted) {
      setState(() {
        _fare = fare;
        _routePoints = route.points;
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    if (!await _ensureLocationPermission()) return;
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
    );
    final point = LatLng(position.latitude, position.longitude);
    setState(() {
      _mode = 'PICKUP';
      _pickup = point;
      _pickupAddress.text =
          'Current GPS pickup (${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)})';
    });
    _mapController?.animateCamera(
      gmaps.CameraUpdate.newLatLngZoom(_g(point), 15),
    );
    await _estimate();
  }

  gmaps.LatLng _g(LatLng point) =>
      gmaps.LatLng(point.latitude, point.longitude);

  Future<bool> _ensureLocationPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission != LocationPermission.denied &&
        permission != LocationPermission.deniedForever;
  }

  Future<void> _confirm() async {
    setState(() => _saving = true);
    final order = await context.read<AppState>().createPickDropOrder(
      pickupAddress: _pickupAddress.text,
      pickupLat: _pickup.latitude,
      pickupLng: _pickup.longitude,
      dropAddress: _dropAddress.text,
      dropLat: _drop.latitude,
      dropLng: _drop.longitude,
      itemType: _itemType.text,
      itemDescription: _itemDescription.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PickDropTrackingScreen(order: order)),
    );
  }
}

class _VehicleOption extends StatelessWidget {
  const _VehicleOption({
    required this.icon,
    required this.title,
    this.selected = false,
  });

  final IconData icon;
  final String title;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xFFD2AB50).withValues(alpha: .20)
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? const Color(0xFFD2AB50) : const Color(0xFFE8E1D6),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF1E1E1E)),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _FareCard extends StatelessWidget {
  const _FareCard({required this.fare, required this.onRefresh});

  final PickDropFare? fare;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.payments_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pay cash after delivery',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  fare == null
                      ? 'Calculating fare...'
                      : '${fare!.distanceKm} km - Nu. ${fare!.baseFare} + Nu. ${fare!.perKmRate}/km',
                ),
              ],
            ),
          ),
          fare == null
              ? IconButton(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded),
                )
              : MoneyText(
                  fare!.estimatedPrice,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
        ],
      ),
    );
  }
}
