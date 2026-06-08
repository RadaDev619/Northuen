import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../models/pickdrop_model.dart';
import '../services/geoapify_routing_service.dart';
import '../services/place_search_service.dart';
import '../state/app_state.dart';
import '../widgets/money_text.dart';
import 'pickdrop_tracking_screen.dart';

const _runnerTeal = NorthuenTheme.customerPrimary;
const _runnerAmber = NorthuenTheme.customerAccent;
const _runnerSage = NorthuenTheme.customerSecondary;
const _softTeal = Color(0xFFFFF7ED);
const _softSage = NorthuenTheme.customerSurfaceAlt;

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
  final _itemDescription = TextEditingController(
    text: 'Documents or small package',
  );
  final _routing = GeoapifyRoutingService();
  final _places = PlaceSearchService();

  gmaps.GoogleMapController? _mapController;
  LatLng _pickup = const LatLng(27.4728, 89.6390);
  LatLng _drop = const LatLng(27.4850, 89.6250);
  List<LatLng> _routePoints = const [];
  PickDropFare? _fare;
  int _step = 0;
  String _pinMode = 'PICKUP';
  String _itemType = 'Small parcel';
  bool _saving = false;
  bool _estimating = false;
  int _addressLookupSerial = 0;

  static const _itemTypes = [
    _ItemTypeOption(
      label: 'Documents',
      icon: Icons.description_rounded,
      hint: 'Letters, papers, certificates',
    ),
    _ItemTypeOption(
      label: 'Small parcel',
      icon: Icons.inventory_2_rounded,
      hint: 'Compact package or box',
    ),
    _ItemTypeOption(
      label: 'Food/item',
      icon: Icons.shopping_bag_rounded,
      hint: 'Packed food or purchased item',
    ),
    _ItemTypeOption(
      label: 'Other',
      icon: Icons.more_horiz_rounded,
      hint: 'Anything small and safe',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pickupAddress.addListener(_onFormChanged);
    _dropAddress.addListener(_onFormChanged);
    _itemDescription.addListener(_onFormChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _estimate());
  }

  @override
  void dispose() {
    _pickupAddress.removeListener(_onFormChanged);
    _dropAddress.removeListener(_onFormChanged);
    _itemDescription.removeListener(_onFormChanged);
    _pickupAddress.dispose();
    _dropAddress.dispose();
    _itemDescription.dispose();
    _places.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        _RequestHero(step: _step),
        const SizedBox(height: 14),
        _StepIndicator(currentStep: _step),
        const SizedBox(height: 18),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: switch (_step) {
            0 => _LocationsStep(
              key: const ValueKey('locations'),
              pickupAddress: _pickupAddress,
              dropAddress: _dropAddress,
              pickup: _pickup,
              drop: _drop,
              routePoints: _routePoints,
              pinMode: _pinMode,
              searchPlaces: _places.search,
              onPlaceSelected: _selectPlace,
              onPinModeChanged: _changePinMode,
              onMapCreated: (controller) => _mapController = controller,
              onMapTap: _pinLocation,
              onMarkerMoved: _pinLocationForMode,
              onUseCurrentLocation: _useCurrentLocation,
            ),
            1 => _ItemStep(
              key: const ValueKey('item'),
              itemType: _itemType,
              itemDescription: _itemDescription,
              itemTypes: _itemTypes,
              onItemTypeChanged: (value) => setState(() => _itemType = value),
            ),
            _ => _ReviewStep(
              key: const ValueKey('review'),
              pickupAddress: _pickupAddress.text,
              dropAddress: _dropAddress.text,
              itemType: _itemType,
              itemDescription: _itemDescription.text,
              fare: _fare,
              estimating: _estimating,
              onRefreshFare: _estimate,
            ),
          },
        ),
        const SizedBox(height: 18),
        _BottomActions(
          step: _step,
          saving: _saving,
          canContinue: _canContinue,
          canPost: _fare != null && !_saving,
          onBack: _step == 0 ? null : () => setState(() => _step--),
          onContinue: _continue,
          onPost: _postRequest,
        ),
      ],
    );
  }

  bool get _canContinue {
    if (_step == 0) {
      return _pickupAddress.text.trim().isNotEmpty &&
          _dropAddress.text.trim().isNotEmpty;
    }
    if (_step == 1) {
      return _itemDescription.text.trim().isNotEmpty;
    }
    return _fare != null;
  }

  void _onFormChanged() {
    if (mounted) setState(() {});
  }

  void _continue() {
    if (!_canContinue) return;
    if (_step == 0) {
      _estimate();
    }
    setState(() => _step = (_step + 1).clamp(0, 2));
  }

  void _changePinMode(String value) {
    setState(() => _pinMode = value);
    final target = value == 'PICKUP' ? _pickup : _drop;
    _mapController?.animateCamera(
      gmaps.CameraUpdate.newLatLngZoom(_g(target), 15),
    );
  }

  Future<void> _selectPlace(String mode, PlaceSuggestion suggestion) async {
    final point = suggestion.point;
    setState(() {
      _pinMode = mode;
      if (mode == 'PICKUP') {
        _pickup = point;
        _pickupAddress.text = suggestion.label;
      } else {
        _drop = point;
        _dropAddress.text = suggestion.label;
      }
    });
    await _mapController?.animateCamera(
      gmaps.CameraUpdate.newLatLngZoom(_g(point), 15),
    );
    await _estimate();
  }

  void _pinLocation(gmaps.LatLng point) {
    _pinLocationForMode(_pinMode, point);
  }

  void _pinLocationForMode(String mode, gmaps.LatLng point) {
    final next = LatLng(point.latitude, point.longitude);
    final lookupSerial = ++_addressLookupSerial;
    setState(() {
      _pinMode = mode;
      if (mode == 'PICKUP') {
        _pickup = next;
        _pickupAddress.text = 'Finding pickup address...';
      } else {
        _drop = next;
        _dropAddress.text = 'Finding drop-off address...';
      }
    });
    _mapController?.animateCamera(gmaps.CameraUpdate.newLatLng(_g(next)));
    unawaited(_resolvePinnedAddress(mode, next, lookupSerial));
    _estimate();
  }

  Future<void> _resolvePinnedAddress(
    String mode,
    LatLng point,
    int lookupSerial,
  ) async {
    final place = await _places.reverse(point);
    if (!mounted || lookupSerial != _addressLookupSerial) return;
    final stillCurrent = mode == 'PICKUP'
        ? _samePoint(_pickup, point)
        : _samePoint(_drop, point);
    if (!stillCurrent) return;
    setState(() {
      if (mode == 'PICKUP') {
        _pickupAddress.text = place.label;
      } else {
        _dropAddress.text = place.label;
      }
    });
  }

  bool _samePoint(LatLng a, LatLng b) {
    return (a.latitude - b.latitude).abs() < 0.000001 &&
        (a.longitude - b.longitude).abs() < 0.000001;
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
    var routePoints = <LatLng>[];
    try {
      final route = await _routing.route(from: _pickup, to: _drop);
      routePoints = route.points;
    } catch (_) {
      routePoints = const [];
    }
    if (mounted) {
      setState(() {
        _fare = fare;
        _routePoints = routePoints;
        _estimating = false;
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    if (!await _ensureLocationPermission()) return;
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
    );
    final point = LatLng(position.latitude, position.longitude);
    final lookupSerial = ++_addressLookupSerial;
    setState(() {
      _pinMode = 'PICKUP';
      _pickup = point;
      _pickupAddress.text = 'Finding pickup address...';
    });
    _mapController?.animateCamera(
      gmaps.CameraUpdate.newLatLngZoom(_g(point), 15),
    );
    unawaited(_resolvePinnedAddress('PICKUP', point, lookupSerial));
    await _estimate();
  }

  Future<bool> _ensureLocationPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (mounted) {
        _showMessage(
          'Location service is off. Turn it on or pin pickup on the map.',
        );
      }
      return false;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    final granted =
        permission != LocationPermission.denied &&
        permission != LocationPermission.deniedForever;
    if (!granted && mounted) {
      _showMessage(
        'Location permission was not granted. You can still type or pin the pickup.',
      );
    }
    return granted;
  }

  Future<void> _postRequest() async {
    if (_fare == null || _saving) return;
    setState(() => _saving = true);
    try {
      final order = await context.read<AppState>().createPickDropOrder(
        pickupAddress: _pickupAddress.text,
        pickupLat: _pickup.latitude,
        pickupLng: _pickup.longitude,
        dropAddress: _dropAddress.text,
        dropLat: _drop.latitude,
        dropLng: _drop.longitude,
        itemType: _itemType,
        itemDescription: _itemDescription.text,
      );
      if (!mounted) return;
      setState(() => _saving = false);
      await _showRequestPosted(order);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage(error.toString());
    }
  }

  Future<void> _showRequestPosted(PickDropOrder order) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Request posted'),
        content: const Text(
          'We are finding a runner for your Pick & Drop request.',
        ),
        actions: [
          FilledButton.icon(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => PickDropTrackingScreen(order: order),
                ),
              );
            },
            icon: const Icon(Icons.route_rounded),
            label: const Text('Track request'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  gmaps.LatLng _g(LatLng point) =>
      gmaps.LatLng(point.latitude, point.longitude);
}

class _RequestHero extends StatelessWidget {
  const _RequestHero({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final title = switch (step) {
      0 => 'Set pickup and drop',
      1 => 'Tell us what to carry',
      _ => 'Review your request',
    };
    final subtitle = switch (step) {
      0 => 'Type the addresses or fine tune them on the map.',
      1 => 'Choose the item type and add a short description.',
      _ => 'Confirm the route, fare, and cash payment.',
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _softSage,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: NorthuenTheme.customerBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .82),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.route_rounded, color: _runnerTeal),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: NorthuenTheme.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: NorthuenTheme.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});

  final int currentStep;

  static const _labels = ['Locations', 'Item', 'Review'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_labels.length, (index) {
        final active = index == currentStep;
        final done = index < currentStep;
        final color = active || done ? _runnerTeal : const Color(0xFFE2E8F0);
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: active ? _softTeal : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: color,
                        child: done
                            ? const Icon(
                                Icons.check_rounded,
                                size: 15,
                                color: Colors.white,
                              )
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: active
                                      ? Colors.white
                                      : NorthuenTheme.muted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _labels[index],
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: active ? _runnerTeal : NorthuenTheme.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (index < _labels.length - 1) const SizedBox(width: 6),
            ],
          ),
        );
      }),
    );
  }
}

class _LocationsStep extends StatelessWidget {
  const _LocationsStep({
    super.key,
    required this.pickupAddress,
    required this.dropAddress,
    required this.pickup,
    required this.drop,
    required this.routePoints,
    required this.pinMode,
    required this.searchPlaces,
    required this.onPlaceSelected,
    required this.onPinModeChanged,
    required this.onMapCreated,
    required this.onMapTap,
    required this.onMarkerMoved,
    required this.onUseCurrentLocation,
  });

  final TextEditingController pickupAddress;
  final TextEditingController dropAddress;
  final LatLng pickup;
  final LatLng drop;
  final List<LatLng> routePoints;
  final String pinMode;
  final Future<List<PlaceSuggestion>> Function(String) searchPlaces;
  final Future<void> Function(String, PlaceSuggestion) onPlaceSelected;
  final ValueChanged<String> onPinModeChanged;
  final ValueChanged<gmaps.GoogleMapController> onMapCreated;
  final ValueChanged<gmaps.LatLng> onMapTap;
  final void Function(String, gmaps.LatLng) onMarkerMoved;
  final Future<void> Function() onUseCurrentLocation;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionCard(
          child: Column(
            children: [
              _AddressField(
                controller: pickupAddress,
                label: 'Pickup location',
                icon: Icons.my_location_rounded,
                active: pinMode == 'PICKUP',
                searchPlaces: searchPlaces,
                onFocused: () => onPinModeChanged('PICKUP'),
                onSelected: (suggestion) =>
                    onPlaceSelected('PICKUP', suggestion),
              ),
              const SizedBox(height: 12),
              _AddressField(
                controller: dropAddress,
                label: 'Drop-off location',
                icon: Icons.location_on_rounded,
                active: pinMode == 'DROP',
                searchPlaces: searchPlaces,
                onFocused: () => onPinModeChanged('DROP'),
                onSelected: (suggestion) => onPlaceSelected('DROP', suggestion),
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: onUseCurrentLocation,
                icon: const Icon(Icons.gps_fixed_rounded),
                label: const Text('Use my current location'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _MapPreview(
          pickup: pickup,
          drop: drop,
          routePoints: routePoints,
          pinMode: pinMode,
          onPinModeChanged: onPinModeChanged,
          onMapCreated: onMapCreated,
          onMapTap: onMapTap,
          onMarkerMoved: onMarkerMoved,
        ),
      ],
    );
  }
}

class _AddressField extends StatefulWidget {
  const _AddressField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.active,
    required this.searchPlaces,
    required this.onFocused,
    required this.onSelected,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool active;
  final Future<List<PlaceSuggestion>> Function(String) searchPlaces;
  final VoidCallback onFocused;
  final Future<void> Function(PlaceSuggestion) onSelected;

  @override
  State<_AddressField> createState() => _AddressFieldState();
}

class _AddressFieldState extends State<_AddressField> {
  final _focusNode = FocusNode();
  Timer? _debounce;
  List<PlaceSuggestion> _suggestions = const [];
  bool _loading = false;
  bool _selecting = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) widget.onFocused();
      if (!_focusNode.hasFocus && mounted) {
        Future<void>.delayed(const Duration(milliseconds: 120), () {
          if (mounted && !_focusNode.hasFocus) {
            setState(() => _suggestions = const []);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          textInputAction: TextInputAction.search,
          onTap: widget.onFocused,
          onChanged: _onChanged,
          onSubmitted: (_) => _selectFirstSuggestion(),
          decoration: InputDecoration(
            labelText: widget.label,
            prefixIcon: Icon(widget.icon),
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Icon(
                    widget.active
                        ? Icons.radio_button_checked_rounded
                        : Icons.search_rounded,
                    color: widget.active ? _runnerTeal : NorthuenTheme.muted,
                  ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: _runnerTeal, width: 1.4),
            ),
          ),
        ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: NorthuenTheme.customerBorder),
            ),
            child: Column(
              children: _suggestions
                  .map(
                    (suggestion) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.place_rounded),
                      title: Text(
                        suggestion.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        suggestion.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _select(suggestion),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  void _onChanged(String value) {
    if (_selecting) {
      _selecting = false;
      return;
    }
    _debounce?.cancel();
    final query = value.trim();
    if (query.length < 3) {
      setState(() {
        _loading = false;
        _suggestions = const [];
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 320), () {
      _search(query);
    });
  }

  Future<void> _search(String query) async {
    if (!mounted) return;
    setState(() => _loading = true);
    final results = await widget.searchPlaces(query);
    if (!mounted || widget.controller.text.trim() != query) return;
    setState(() {
      _loading = false;
      _suggestions = results;
    });
  }

  Future<void> _selectFirstSuggestion() async {
    if (_suggestions.isNotEmpty) {
      await _select(_suggestions.first);
      return;
    }
    final query = widget.controller.text.trim();
    if (query.length < 3) return;
    final results = await widget.searchPlaces(query);
    if (!mounted || results.isEmpty) return;
    await _select(results.first);
  }

  Future<void> _select(PlaceSuggestion suggestion) async {
    _selecting = true;
    widget.controller.text = suggestion.label;
    widget.controller.selection = TextSelection.collapsed(
      offset: widget.controller.text.length,
    );
    setState(() => _suggestions = const []);
    _focusNode.unfocus();
    await widget.onSelected(suggestion);
  }
}

class _MapPreview extends StatelessWidget {
  const _MapPreview({
    required this.pickup,
    required this.drop,
    required this.routePoints,
    required this.pinMode,
    required this.onPinModeChanged,
    required this.onMapCreated,
    required this.onMapTap,
    required this.onMarkerMoved,
  });

  final LatLng pickup;
  final LatLng drop;
  final List<LatLng> routePoints;
  final String pinMode;
  final ValueChanged<String> onPinModeChanged;
  final ValueChanged<gmaps.GoogleMapController> onMapCreated;
  final ValueChanged<gmaps.LatLng> onMapTap;
  final void Function(String, gmaps.LatLng) onMarkerMoved;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  pinMode == 'PICKUP'
                      ? 'Setting pickup point'
                      : 'Setting drop-off point',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'PICKUP',
                    label: Text('Pickup'),
                    icon: Icon(Icons.my_location_rounded),
                  ),
                  ButtonSegment(
                    value: 'DROP',
                    label: Text('Drop'),
                    icon: Icon(Icons.location_on_rounded),
                  ),
                ],
                selected: {pinMode},
                onSelectionChanged: (value) => onPinModeChanged(value.first),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _softTeal,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: NorthuenTheme.customerBorder),
            ),
            child: Row(
              children: [
                Icon(
                  pinMode == 'PICKUP'
                      ? Icons.my_location_rounded
                      : Icons.location_on_rounded,
                  color: _runnerTeal,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pinMode == 'PICKUP'
                        ? 'Tap the map or drag the pickup marker.'
                        : 'Tap the map or drag the drop-off marker.',
                    style: const TextStyle(
                      color: NorthuenTheme.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 220,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: gmaps.GoogleMap(
                initialCameraPosition: gmaps.CameraPosition(
                  target: _g(pickup),
                  zoom: 13,
                ),
                onMapCreated: onMapCreated,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                onTap: onMapTap,
                polylines: {
                  gmaps.Polyline(
                    polylineId: const gmaps.PolylineId('route'),
                    points: (routePoints.isEmpty ? [pickup, drop] : routePoints)
                        .map(_g)
                        .toList(),
                    width: 5,
                    color: _runnerTeal,
                  ),
                },
                markers: {
                  gmaps.Marker(
                    markerId: const gmaps.MarkerId('pickup'),
                    position: _g(pickup),
                    draggable: true,
                    icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
                      pinMode == 'PICKUP'
                          ? gmaps.BitmapDescriptor.hueOrange
                          : gmaps.BitmapDescriptor.hueAzure,
                    ),
                    onTap: () => onPinModeChanged('PICKUP'),
                    onDragEnd: (point) => onMarkerMoved('PICKUP', point),
                    infoWindow: const gmaps.InfoWindow(title: 'Pickup'),
                  ),
                  gmaps.Marker(
                    markerId: const gmaps.MarkerId('drop'),
                    position: _g(drop),
                    draggable: true,
                    icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
                      pinMode == 'DROP'
                          ? gmaps.BitmapDescriptor.hueOrange
                          : gmaps.BitmapDescriptor.hueRed,
                    ),
                    onTap: () => onPinModeChanged('DROP'),
                    onDragEnd: (point) => onMarkerMoved('DROP', point),
                    infoWindow: const gmaps.InfoWindow(title: 'Drop'),
                  ),
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Address suggestions update the pin; the map is for fine tuning.',
            style: TextStyle(
              color: NorthuenTheme.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  static gmaps.LatLng _g(LatLng point) =>
      gmaps.LatLng(point.latitude, point.longitude);
}

class _ItemStep extends StatelessWidget {
  const _ItemStep({
    super.key,
    required this.itemType,
    required this.itemDescription,
    required this.itemTypes,
    required this.onItemTypeChanged,
  });

  final String itemType;
  final TextEditingController itemDescription;
  final List<_ItemTypeOption> itemTypes;
  final ValueChanged<String> onItemTypeChanged;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What are you sending?',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 12),
          ...itemTypes.map(
            (option) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ItemTypeCard(
                option: option,
                selected: itemType == option.label,
                onTap: () => onItemTypeChanged(option.label),
              ),
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: itemDescription,
            decoration: const InputDecoration(
              labelText: 'Item description',
              prefixIcon: Icon(Icons.edit_note_rounded),
            ),
            minLines: 3,
            maxLines: 4,
          ),
        ],
      ),
    );
  }
}

class _ItemTypeCard extends StatelessWidget {
  const _ItemTypeCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _ItemTypeOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 70),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? _softTeal : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? _runnerTeal : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: selected ? _runnerTeal : Colors.white,
              child: Icon(
                option.icon,
                color: selected ? Colors.white : NorthuenTheme.ink,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.hint,
                    style: const TextStyle(
                      color: NorthuenTheme.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: _runnerTeal),
          ],
        ),
      ),
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    super.key,
    required this.pickupAddress,
    required this.dropAddress,
    required this.itemType,
    required this.itemDescription,
    required this.fare,
    required this.estimating,
    required this.onRefreshFare,
  });

  final String pickupAddress;
  final String dropAddress;
  final String itemType;
  final String itemDescription;
  final PickDropFare? fare;
  final bool estimating;
  final Future<void> Function() onRefreshFare;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionCard(
          child: Column(
            children: [
              _ReviewRow(
                icon: Icons.my_location_rounded,
                title: 'Pickup',
                value: pickupAddress,
                color: _runnerTeal,
              ),
              const Divider(height: 24),
              _ReviewRow(
                icon: Icons.location_on_rounded,
                title: 'Drop-off',
                value: dropAddress,
                color: _runnerAmber,
              ),
              const Divider(height: 24),
              _ReviewRow(
                icon: Icons.inventory_2_rounded,
                title: itemType,
                value: itemDescription,
                color: _runnerSage,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _FareCard(fare: fare, estimating: estimating, onRefresh: onRefreshFare),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: color.withValues(alpha: .14),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: NorthuenTheme.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FareCard extends StatelessWidget {
  const _FareCard({
    required this.fare,
    required this.estimating,
    required this.onRefresh,
  });

  final PickDropFare? fare;
  final bool estimating;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      background: _softSage,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _runnerSage,
            child: estimating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.payments_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cash after delivery',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  fare == null
                      ? 'Calculating estimated fare'
                      : '${fare!.distanceKm} km route. Nu. ${fare!.baseFare} base + Nu. ${fare!.perKmRate}/km.',
                  style: const TextStyle(
                    color: NorthuenTheme.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          fare == null
              ? IconButton(
                  tooltip: 'Refresh fare',
                  onPressed: estimating ? null : onRefresh,
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

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.step,
    required this.saving,
    required this.canContinue,
    required this.canPost,
    required this.onBack,
    required this.onContinue,
    required this.onPost,
  });

  final int step;
  final bool saving;
  final bool canContinue;
  final bool canPost;
  final VoidCallback? onBack;
  final VoidCallback onContinue;
  final VoidCallback onPost;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onBack != null) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: saving ? null : onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Back'),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: _runnerTeal,
              foregroundColor: Colors.white,
            ),
            onPressed: saving
                ? null
                : step == 2
                ? canPost
                      ? onPost
                      : null
                : canContinue
                ? onContinue
                : null,
            icon: Icon(
              step == 2
                  ? Icons.check_circle_rounded
                  : Icons.arrow_forward_rounded,
            ),
            label: Text(
              saving
                  ? 'Posting request...'
                  : step == 2
                  ? 'Post Request'
                  : 'Continue',
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.background = Colors.white,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: background,
      child: Padding(padding: padding, child: child),
    );
  }
}

class _ItemTypeOption {
  const _ItemTypeOption({
    required this.label,
    required this.icon,
    required this.hint,
  });

  final String label;
  final IconData icon;
  final String hint;
}
