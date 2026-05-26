import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/tracking_api.dart';
import '../utils/polyline.dart';
import '../widgets/tracking_info_card.dart';

class RunnerNavigationScreen extends StatefulWidget {
  const RunnerNavigationScreen({
    super.key,
    required this.orderId,
    required this.runnerId,
    required this.orderStatus,
    required this.pickup,
    required this.dropoff,
  });

  final String orderId;
  final String runnerId;
  final String orderStatus;
  final LatLngPoint pickup;
  final LatLngPoint dropoff;

  @override
  State<RunnerNavigationScreen> createState() => _RunnerNavigationScreenState();
}

class _RunnerNavigationScreenState extends State<RunnerNavigationScreen> {
  static const _api = TrackingApi();
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionSub;
  LatLng? _runner;
  double _heading = 0;
  bool _tracking = false;
  String? _message;
  RouteSnapshot? _route;
  List<LatLng> _routePoints = [];
  DateTime? _lastRouteAt;

  bool get _activeStatus =>
      {'accepted', 'picked_up', 'on_the_way'}.contains(widget.orderStatus);

  LatLngPoint get _destination =>
      widget.orderStatus == 'accepted' ? widget.pickup : widget.dropoff;

  String get _nextAction =>
      widget.orderStatus == 'accepted' ? 'Head to pickup' : 'Head to customer';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshRoute(true));
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pickup = LatLng(widget.pickup.lat, widget.pickup.lng);
    final dropoff = LatLng(widget.dropoff.lat, widget.dropoff.lng);
    final runner = _runner ?? pickup;
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: pickup, zoom: 13),
          onMapCreated: (controller) => _mapController = controller,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          compassEnabled: false,
          zoomControlsEnabled: false,
          markers: {
            Marker(
              markerId: const MarkerId('pickup'),
              position: pickup,
              infoWindow: const InfoWindow(title: 'Pickup'),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
            ),
            Marker(
              markerId: const MarkerId('dropoff'),
              position: dropoff,
              infoWindow: const InfoWindow(title: 'Drop-off'),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
            ),
            Marker(
              markerId: const MarkerId('runner'),
              position: runner,
              rotation: _heading,
              flat: true,
              anchor: const Offset(.5, .5),
              infoWindow: const InfoWindow(title: 'Runner'),
            ),
          },
          polylines: {
            if (_routePoints.isNotEmpty)
              Polyline(
                polylineId: const PolylineId('route'),
                points: _routePoints,
                color: const Color(0xff2563eb),
                width: 6,
              ),
          },
        ),
        TrackingInfoCard(
          title: _nextAction,
          status: widget.orderStatus,
          distanceMeters: _route?.distanceMeters,
          durationSeconds: _route?.durationSeconds,
        ),
        if (_message != null)
          Positioned(
            left: 16,
            right: 16,
            top: 112,
            child: Material(
              color: Colors.white,
              elevation: 2,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_message!),
              ),
            ),
          ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                onPressed: _tracking ? _stopTracking : _startTracking,
                icon: Icon(
                  _tracking
                      ? Icons.location_disabled_rounded
                      : Icons.my_location_rounded,
                ),
                label: Text(_tracking ? 'Stop tracking' : 'Start tracking'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _runner == null ? null : _recenter,
                icon: const Icon(Icons.explore_rounded),
                label: const Text('Recenter'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _startTracking() async {
    if (!_activeStatus) {
      setState(() => _message = 'Tracking starts only after acceptance.');
      return;
    }
    if (!await _ensurePermission()) return;

    await _positionSub?.cancel();
    setState(() {
      _tracking = true;
      _message = 'Live GPS tracking started.';
    });

    const settings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 8,
    );
    _positionSub =
        Geolocator.getPositionStream(locationSettings: settings).listen(
      (position) => _handlePosition(position),
      onError: (Object error) {
        setState(() {
          _tracking = false;
          _message = 'GPS tracking stopped: $error';
        });
      },
    );

    final current = await Geolocator.getCurrentPosition(
      locationSettings: settings,
    );
    await _handlePosition(current);
  }

  Future<void> _stopTracking() async {
    await _positionSub?.cancel();
    _positionSub = null;
    if (!mounted) return;
    setState(() {
      _tracking = false;
      _message = 'Live GPS tracking stopped.';
    });
  }

  Future<void> _handlePosition(Position position) async {
    final next = LatLng(position.latitude, position.longitude);
    setState(() {
      _runner = next;
      _heading = position.heading.isNaN ? _heading : position.heading;
    });

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: next,
          zoom: 17,
          tilt: 55,
          bearing: _heading,
        ),
      ),
    );

    try {
      await _api.sendRunnerLocation(
        orderId: widget.orderId,
        runnerId: widget.runnerId,
        status: widget.orderStatus,
        lat: position.latitude,
        lng: position.longitude,
        heading: position.heading.isNaN ? null : position.heading,
        speed: position.speed.isNaN ? null : position.speed,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
      );
      await _refreshRoute(false);
    } catch (error) {
      if (mounted) setState(() => _message = error.toString());
    }
  }

  Future<void> _refreshRoute(bool force) async {
    final now = DateTime.now();
    if (!force &&
        _lastRouteAt != null &&
        now.difference(_lastRouteAt!) < const Duration(seconds: 45)) {
      return;
    }
    final origin = _runner == null
        ? widget.pickup
        : LatLngPoint(lat: _runner!.latitude, lng: _runner!.longitude);
    try {
      final route = await _api.requestRoute(
        orderId: widget.orderId,
        origin: origin,
        destination: _destination,
        force: force,
      );
      if (route == null || !mounted) return;
      setState(() {
        _route = route;
        _routePoints = decodePolyline(route.encodedPolyline);
        _lastRouteAt = now;
      });
    } catch (error) {
      if (mounted) setState(() => _message = error.toString());
    }
  }

  void _recenter() {
    final runner = _runner;
    if (runner == null) return;
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: runner,
          zoom: 17,
          tilt: 55,
          bearing: _heading,
        ),
      ),
    );
  }

  Future<bool> _ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      setState(() => _message = 'Turn on phone location services.');
      return false;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() => _message = 'Location permission is required.');
      return false;
    }
    return true;
  }
}
