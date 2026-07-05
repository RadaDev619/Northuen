import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
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
  final _routing = GeoapifyRoutingService();

  gmaps.GoogleMapController? _mapController;
  LatLng _pickup = const LatLng(27.4728, 89.6390);
  LatLng _drop = const LatLng(27.4850, 89.6250);
  List<LatLng> _routePoints = const [];
  String _pinMode = 'PICKUP';
  PickDropFare? _fare;
  bool _estimating = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _estimate());
  }

  @override
  void dispose() {
    _pickupAddress.dispose();
    _dropAddress.dispose();
    _itemType.dispose();
    _itemDescription.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Book Pick & Drop'),
            Text(
              'Fast local delivery by bike',
              style: TextStyle(
                color: NorthuenTheme.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * .31,
            child: Stack(
              children: [
                Positioned.fill(child: _buildMap(context)),
                Positioned(
                  left: 12,
                  right: 12,
                  top: 12,
                  child: _PinModeControl(
                    value: _pinMode,
                    onChanged: (value) => setState(() => _pinMode = value),
                    onUseGps: _useCurrentLocation,
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: FloatingActionButton.small(
                    heroTag: 'fit-pickdrop-route',
                    tooltip: 'Fit route',
                    backgroundColor: Colors.white,
                    foregroundColor: NorthuenTheme.primary,
                    onPressed: _fitRoute,
                    child: const Icon(Icons.center_focus_strong_rounded),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: NorthuenTheme.background,
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  16,
                  18,
                  16,
                  bottomInset > 0 ? 24 : 112,
                ),
                children: [
                  Text(
                    'Where should your runner go?',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Enter the addresses or tap the map to move the selected pin.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: NorthuenTheme.muted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _RouteFields(
                    pickupController: _pickupAddress,
                    dropController: _dropAddress,
                    activeMode: _pinMode,
                    onPickupSelected: () => setState(() => _pinMode = 'PICKUP'),
                    onDropSelected: () => setState(() => _pinMode = 'DROP'),
                  ),
                  const SizedBox(height: 16),
                  const _ServiceCard(),
                  const SizedBox(height: 16),
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
                            controller: _itemType,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'What are you sending?',
                              hintText: 'Documents, food, small parcel',
                              prefixIcon: Icon(Icons.inventory_2_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _itemDescription,
                            decoration: const InputDecoration(
                              labelText: 'Runner instructions',
                              hintText:
                                  'Package size, contact person, or handover notes',
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
                  const SizedBox(height: 16),
                  _FareSummary(
                    fare: _fare,
                    estimating: _estimating,
                    onRefresh: _estimate,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: bottomInset > 0
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: NorthuenTheme.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Estimated total',
                            style: TextStyle(
                              color: NorthuenTheme.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          _fare == null
                              ? const Text(
                                  'Calculating...',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                )
                              : MoneyText(
                                  _fare!.estimatedPrice,
                                  style: const TextStyle(
                                    color: NorthuenTheme.primary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _saving || _fare == null ? null : _confirm,
                        icon: _saving
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.delivery_dining_rounded),
                        label: Text(
                          _saving ? 'Finding runner...' : 'Book runner',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMap(BuildContext context) {
    return gmaps.GoogleMap(
      initialCameraPosition: gmaps.CameraPosition(
        target: _g(_pickup),
        zoom: 13,
      ),
      onMapCreated: (controller) {
        _mapController = controller;
        _fitRoute();
      },
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      onTap: (point) {
        final next = LatLng(point.latitude, point.longitude);
        setState(() {
          if (_pinMode == 'PICKUP') {
            _pickup = next;
            _pickupAddress.text =
                'Pinned pickup • ${next.latitude.toStringAsFixed(5)}, ${next.longitude.toStringAsFixed(5)}';
          } else {
            _drop = next;
            _dropAddress.text =
                'Pinned drop-off • ${next.latitude.toStringAsFixed(5)}, ${next.longitude.toStringAsFixed(5)}';
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
          width: 6,
          color: NorthuenTheme.primary,
          startCap: gmaps.Cap.roundCap,
          endCap: gmaps.Cap.roundCap,
        ),
      },
      markers: {
        gmaps.Marker(
          markerId: const gmaps.MarkerId('pickup'),
          position: _g(_pickup),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueGreen,
          ),
          infoWindow: const gmaps.InfoWindow(title: 'Pickup point'),
        ),
        gmaps.Marker(
          markerId: const gmaps.MarkerId('drop'),
          position: _g(_drop),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueOrange,
          ),
          infoWindow: const gmaps.InfoWindow(title: 'Drop-off point'),
        ),
      },
    );
  }

  Future<void> _estimate() async {
    if (!mounted) return;
    setState(() => _estimating = true);
    final fare = await context.read<AppState>().estimatePickDropFare(
      pickupLat: _pickup.latitude,
      pickupLng: _pickup.longitude,
      dropLat: _drop.latitude,
      dropLng: _drop.longitude,
    );
    final route = await _routing.route(from: _pickup, to: _drop);
    if (!mounted) return;
    setState(() {
      _fare = fare;
      _routePoints = route.points;
      _estimating = false;
    });
    _fitRoute();
  }

  Future<void> _useCurrentLocation() async {
    if (!await _ensureLocationPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enable location permission to use your GPS pickup.'),
          ),
        );
      }
      return;
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
    );
    final point = LatLng(position.latitude, position.longitude);
    if (!mounted) return;
    setState(() {
      _pinMode = 'PICKUP';
      _pickup = point;
      _pickupAddress.text =
          'Current GPS location • ${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
    });
    _mapController?.animateCamera(
      gmaps.CameraUpdate.newLatLngZoom(_g(point), 15),
    );
    await _estimate();
  }

  Future<void> _fitRoute() async {
    final controller = _mapController;
    if (controller == null) return;
    final south = _pickup.latitude < _drop.latitude
        ? _pickup.latitude
        : _drop.latitude;
    final north = _pickup.latitude > _drop.latitude
        ? _pickup.latitude
        : _drop.latitude;
    final west = _pickup.longitude < _drop.longitude
        ? _pickup.longitude
        : _drop.longitude;
    final east = _pickup.longitude > _drop.longitude
        ? _pickup.longitude
        : _drop.longitude;
    await controller.animateCamera(
      gmaps.CameraUpdate.newLatLngBounds(
        gmaps.LatLngBounds(
          southwest: gmaps.LatLng(south, west),
          northeast: gmaps.LatLng(north, east),
        ),
        58,
      ),
    );
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
    if (_pickupAddress.text.trim().isEmpty ||
        _dropAddress.text.trim().isEmpty ||
        _itemType.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add pickup, drop-off, and package details first.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final order = await context.read<AppState>().createPickDropOrder(
        pickupAddress: _pickupAddress.text.trim(),
        pickupLat: _pickup.latitude,
        pickupLng: _pickup.longitude,
        dropAddress: _dropAddress.text.trim(),
        dropLat: _drop.latitude,
        dropLng: _drop.longitude,
        itemType: _itemType.text.trim(),
        itemDescription: _itemDescription.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => PickDropTrackingScreen(order: order)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _PinModeControl extends StatelessWidget {
  const _PinModeControl({
    required this.value,
    required this.onChanged,
    required this.onUseGps,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onUseGps;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            Expanded(
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'PICKUP',
                    icon: Icon(Icons.trip_origin_rounded, size: 17),
                    label: Text('Set pickup'),
                  ),
                  ButtonSegment(
                    value: 'DROP',
                    icon: Icon(Icons.location_on_rounded, size: 17),
                    label: Text('Set drop-off'),
                  ),
                ],
                selected: {value},
                onSelectionChanged: (selection) => onChanged(selection.first),
                showSelectedIcon: false,
              ),
            ),
            const SizedBox(width: 6),
            IconButton.filledTonal(
              tooltip: 'Use current location',
              onPressed: onUseGps,
              icon: const Icon(Icons.my_location_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteFields extends StatelessWidget {
  const _RouteFields({
    required this.pickupController,
    required this.dropController,
    required this.activeMode,
    required this.onPickupSelected,
    required this.onDropSelected,
  });

  final TextEditingController pickupController;
  final TextEditingController dropController;
  final String activeMode;
  final VoidCallback onPickupSelected;
  final VoidCallback onDropSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 17),
              child: Column(
                children: [
                  const Icon(
                    Icons.trip_origin_rounded,
                    color: NorthuenTheme.success,
                    size: 17,
                  ),
                  Container(
                    width: 2,
                    height: 57,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    color: NorthuenTheme.border,
                  ),
                  const Icon(
                    Icons.location_on_rounded,
                    color: NorthuenTheme.orange,
                    size: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                children: [
                  TextField(
                    controller: pickupController,
                    onTap: onPickupSelected,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Pickup address',
                      hintText: 'Where should the runner collect it?',
                      fillColor: activeMode == 'PICKUP'
                          ? NorthuenTheme.success.withValues(alpha: .05)
                          : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: dropController,
                    onTap: onDropSelected,
                    decoration: InputDecoration(
                      labelText: 'Drop-off address',
                      hintText: 'Where should it be delivered?',
                      fillColor: activeMode == 'DROP'
                          ? NorthuenTheme.orange.withValues(alpha: .05)
                          : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: NorthuenTheme.teal.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.two_wheeler_rounded,
                color: NorthuenTheme.teal,
                size: 27,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bike runner',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Best for documents and small packages',
                    style: TextStyle(color: NorthuenTheme.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: NorthuenTheme.success.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Selected',
                style: TextStyle(
                  color: NorthuenTheme.success,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FareSummary extends StatelessWidget {
  const _FareSummary({
    required this.fare,
    required this.estimating,
    required this.onRefresh,
  });

  final PickDropFare? fare;
  final bool estimating;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NorthuenTheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: estimating || fare == null
          ? const Row(
              children: [
                SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Calculating distance and fare...',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estimated fare',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Pay cash after delivery',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    MoneyText(
                      fare!.estimatedPrice,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _FareDetail(
                        label: 'Distance',
                        value: '${fare!.distanceKm} km',
                      ),
                      Container(width: 1, height: 34, color: Colors.white24),
                      _FareDetail(
                        label: 'Base fare',
                        value: 'Nu. ${fare!.baseFare}',
                      ),
                      Container(width: 1, height: 34, color: Colors.white24),
                      _FareDetail(
                        label: 'Per km',
                        value: 'Nu. ${fare!.perKmRate}',
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh_rounded, size: 17),
                    label: const Text('Refresh estimate'),
                  ),
                ),
              ],
            ),
    );
  }
}

class _FareDetail extends StatelessWidget {
  const _FareDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 10),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
