import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../models/navigation_route_model.dart';
import '../models/pickdrop_model.dart';
import '../services/api_client.dart';
import '../services/tracking_route_service.dart';
import '../state/app_state.dart';
import '../widgets/pickdrop_incoming_call_banner.dart';
import '../widgets/tracking/direction_hint_card.dart';
import '../widgets/tracking/eta_bottom_sheet.dart';
import '../widgets/tracking/navigation_status_pill.dart';
import '../widgets/tracking/order_progress_timeline.dart';
import '../widgets/tracking/tracking_map.dart';
import 'pickdrop_call_screen.dart';
import 'pickdrop_chat_screen.dart';

class PickDropDriverScreen extends StatefulWidget {
  const PickDropDriverScreen({super.key, required this.order});

  final PickDropOrder order;

  @override
  State<PickDropDriverScreen> createState() => _PickDropDriverScreenState();
}

class _PickDropDriverScreenState extends State<PickDropDriverScreen> {
  StreamSubscription<Position>? _positionSubscription;
  late PickDropOrder _order;
  LatLng? _driverLocation;
  NavigationRoute _route = const NavigationRoute(points: []);
  DateTime? _lastRouteAt;
  double _heading = 0;
  bool _tracking = false;
  bool _autoFollow = true;
  bool _loadingRoute = false;
  bool _poorGps = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadRoute(force: true));
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pickup = LatLng(
      _order.pickupLat.toDouble(),
      _order.pickupLng.toDouble(),
    );
    final dropoff = LatLng(
      _order.dropLat.toDouble(),
      _order.dropLng.toDouble(),
    );
    final runner = _driverLocation ?? pickup;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          TrackingMap(
            runner: runner,
            pickup: pickup,
            dropoff: dropoff,
            heading: _heading,
            activeRoute: _route.points.isEmpty
                ? [runner, _destination]
                : _route.points,
            destination: _destination,
            destinationLabel: _isAfterPickup
                ? 'Destination: customer drop-off'
                : 'Destination: pickup point',
            completedRoute: _completedRoute(pickup, dropoff),
            autoFollow: _autoFollow,
            navigationMode: _tracking,
            initialFitAll: !_tracking,
            onAutoFollowChanged: (value) => setState(() => _autoFollow = value),
            onMarkerTap: _showMarkerAddress,
          ),
          Positioned(
            left: 14,
            top: 12 + MediaQuery.of(context).padding.top,
            child: Material(
              color: Colors.white,
              elevation: 10,
              shadowColor: Colors.black.withValues(alpha: .12),
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
          ),
          Positioned(
            left: 70,
            right: 70,
            top: 14 + MediaQuery.of(context).padding.top,
            child: Center(
              child: NavigationStatusPill(label: _statusLabel, live: _tracking),
            ),
          ),
          Positioned(
            left: 16,
            right: 74,
            top: 74 + MediaQuery.of(context).padding.top,
            child: DirectionHintCard(
              step: _route.primaryStep,
              loading: _loadingRoute,
              warning: _poorGps
                  ? 'Poor GPS signal, updating location...'
                  : _message,
            ),
          ),
          EtaBottomSheet(
            initialSize: .31,
            minSize: .21,
            maxSize: .70,
            currentTask: _currentTask,
            eta: _route.etaLabel,
            distance: _route.distanceLabel,
            customerName: 'Customer',
            orderStatus: _cleanStatus(_order.status),
            onCall: _chatEnabled ? _openCall : null,
            onMessage: _chatEnabled ? _openChat : null,
            primaryLabel: _tracking ? 'Pause GPS' : 'Start navigation',
            primaryIcon: _tracking
                ? Icons.location_disabled_rounded
                : Icons.navigation_rounded,
            onPrimary: _tracking ? _stopTracking : () => _startTracking(),
            secondaryLabel: 'End delivery',
            secondaryIcon: Icons.flag_rounded,
            onSecondary: _complete,
            progress: OrderProgressTimeline(
              steps: const ['Pickup', 'On way', 'Delivered'],
              currentIndex: _driverProgressIndex,
            ),
            extraContent: Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: _RunnerActions(
                onRoutePickup: () => _routeTo(pickup),
                onRouteDropoff: () => _routeTo(dropoff),
                onArrivedPickup: () => _status('ARRIVED_PICKUP'),
                onPickedUp: () => _status('PICKED_UP'),
                onArrivedDrop: () => _status('ARRIVED_DROP'),
              ),
            ),
          ),
          PickDropIncomingCallBanner(
            order: _order,
            top: 132 + MediaQuery.of(context).padding.top,
          ),
        ],
      ),
    );
  }

  LatLng get _destination {
    final dropoff = LatLng(
      _order.dropLat.toDouble(),
      _order.dropLng.toDouble(),
    );
    final pickup = LatLng(
      _order.pickupLat.toDouble(),
      _order.pickupLng.toDouble(),
    );
    return _isAfterPickup ? dropoff : pickup;
  }

  bool get _isAfterPickup =>
      _order.status == 'PICKED_UP' ||
      _order.status == 'ARRIVED_DROP' ||
      _order.status == 'DELIVERED';

  bool get _chatEnabled =>
      _order.driverId != null &&
      _order.status != 'PENDING' &&
      _order.status != 'DRIVER_ASSIGNED';

  String get _currentTask =>
      _isAfterPickup ? 'Deliver to customer' : 'Go to pickup';

  String get _statusLabel {
    if (_order.status == 'ARRIVED_DROP') return 'Arriving soon';
    if (_isAfterPickup) return 'On the way to customer';
    return 'Navigating to pickup';
  }

  int get _driverProgressIndex {
    if (_order.status == 'DELIVERED') return 2;
    if (_isAfterPickup) return 1;
    return 0;
  }

  List<LatLng> _completedRoute(LatLng pickup, LatLng dropoff) {
    if (!_isAfterPickup) return const [];
    return [pickup, _driverLocation ?? pickup];
  }

  Future<bool> _ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      setState(
        () => _message = 'Turn on device location to send live tracking.',
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
        () => _message = 'Location permission is required for tracking.',
      );
      return false;
    }
    return true;
  }

  Future<void> _startTracking() async {
    if (!await _ensurePermission()) return;
    if (!mounted) return;
    final app = context.read<AppState>();
    await _positionSubscription?.cancel();
    setState(() {
      _tracking = true;
      _autoFollow = true;
      _message = null;
    });

    const settings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 8,
    );
    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: settings).listen(
          (position) async {
            final next = LatLng(position.latitude, position.longitude);
            setState(() {
              _driverLocation = next;
              _heading = position.heading.isNaN ? _heading : position.heading;
              _poorGps = position.accuracy > 40;
            });
            final snapped = await app.sendPickDropLocation(
              _order.id,
              position.latitude,
              position.longitude,
              heading: position.heading.isNaN ? null : position.heading,
              speed: position.speed.isNaN ? null : position.speed,
            );
            if (mounted) {
              setState(() {
                _driverLocation = LatLng(
                  snapped.lat.toDouble(),
                  snapped.lng.toDouble(),
                );
              });
            }
            unawaited(_loadRoute());
          },
          onError: (error) {
            setState(() {
              _tracking = false;
              _message = 'GPS tracking stopped: $error';
            });
          },
        );
    await _sendCurrent();
  }

  Future<void> _sendCurrent() async {
    if (!await _ensurePermission()) return;
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
      ),
    );
    if (!mounted) return;
    setState(() {
      _driverLocation = LatLng(position.latitude, position.longitude);
      _heading = position.heading.isNaN ? _heading : position.heading;
      _poorGps = position.accuracy > 40;
    });
    final snapped = await context.read<AppState>().sendPickDropLocation(
      _order.id,
      position.latitude,
      position.longitude,
      heading: position.heading.isNaN ? null : position.heading,
      speed: position.speed.isNaN ? null : position.speed,
    );
    if (!mounted) return;
    setState(() {
      _driverLocation = LatLng(snapped.lat.toDouble(), snapped.lng.toDouble());
    });
    await _loadRoute(force: true);
  }

  Future<void> _stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    if (mounted) setState(() => _tracking = false);
  }

  Future<void> _status(String status) async {
    await _sendCurrent();
    if (!mounted) return;
    final updated = await context.read<AppState>().updatePickDropStatus(
      _order.id,
      status,
    );
    if (!mounted) return;
    setState(() {
      if (updated != null) _order = updated;
      _message = _cleanStatus(status);
    });
    await _loadRoute(force: true);
  }

  Future<void> _complete() async {
    await _sendCurrent();
    await _positionSubscription?.cancel();
    if (!mounted) return;
    await context.read<AppState>().completePickDrop(_order.id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _routeTo(LatLng destination) async {
    setState(() {
      _message = destination == _destination ? null : 'Route updated';
      _autoFollow = true;
    });
    await _loadRoute(force: true, overrideDestination: destination);
  }

  Future<void> _loadRoute({
    bool force = false,
    LatLng? overrideDestination,
  }) async {
    final now = DateTime.now();
    if (!force &&
        _lastRouteAt != null &&
        now.difference(_lastRouteAt!) < const Duration(seconds: 45)) {
      return;
    }
    final pickup = LatLng(
      _order.pickupLat.toDouble(),
      _order.pickupLng.toDouble(),
    );
    final from = _driverLocation ?? pickup;
    final to = overrideDestination ?? _destination;
    setState(() => _loadingRoute = true);
    final route = await TrackingRouteService(
      context.read<ApiClient>(),
    ).route(orderId: _order.id, from: from, to: to, force: force);
    if (!mounted) return;
    setState(() {
      _route = route;
      _lastRouteAt = now;
      _loadingRoute = false;
    });
  }

  void _openChat() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PickDropChatScreen(order: _order)),
    );
  }

  void _openCall() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PickDropCallScreen(order: _order)),
    );
  }

  void _showMarkerAddress(TrackingMarkerKind kind) {
    final title = switch (kind) {
      TrackingMarkerKind.runner => 'Runner',
      TrackingMarkerKind.pickup => 'Pickup',
      TrackingMarkerKind.dropoff => 'Drop-off',
    };
    final address = switch (kind) {
      TrackingMarkerKind.runner =>
        _driverLocation == null
            ? 'Waiting for live GPS'
            : 'Live location updating',
      TrackingMarkerKind.pickup => _order.pickupAddress,
      TrackingMarkerKind.dropoff => _order.dropAddress,
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$title: $address')));
  }

  String _cleanStatus(String status) {
    final lower = status.replaceAll('_', ' ').toLowerCase();
    return lower.isEmpty ? status : lower[0].toUpperCase() + lower.substring(1);
  }
}

class _RunnerActions extends StatelessWidget {
  const _RunnerActions({
    required this.onRoutePickup,
    required this.onRouteDropoff,
    required this.onArrivedPickup,
    required this.onPickedUp,
    required this.onArrivedDrop,
  });

  final VoidCallback onRoutePickup;
  final VoidCallback onRouteDropoff;
  final VoidCallback onArrivedPickup;
  final VoidCallback onPickedUp;
  final VoidCallback onArrivedDrop;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        FilledButton.tonalIcon(
          onPressed: onRoutePickup,
          icon: const Icon(Icons.storefront_rounded),
          label: const Text('Route to pickup'),
        ),
        FilledButton.tonalIcon(
          onPressed: onRouteDropoff,
          icon: const Icon(Icons.home_rounded),
          label: const Text('Route to drop'),
        ),
        OutlinedButton.icon(
          onPressed: onArrivedPickup,
          icon: const Icon(Icons.pin_drop_rounded),
          label: const Text('Arrived pickup'),
        ),
        OutlinedButton.icon(
          onPressed: onPickedUp,
          icon: const Icon(Icons.inventory_2_rounded),
          label: const Text('Picked up'),
        ),
        OutlinedButton.icon(
          onPressed: onArrivedDrop,
          icon: const Icon(Icons.flag_rounded),
          label: const Text('Arrived drop'),
        ),
      ],
    );
  }
}
