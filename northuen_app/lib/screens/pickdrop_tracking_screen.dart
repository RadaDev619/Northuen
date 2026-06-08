import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../core/config.dart';
import '../models/navigation_route_model.dart';
import '../models/pickdrop_model.dart';
import '../services/api_client.dart';
import '../services/realtime_tracking_service.dart';
import '../services/tracking_route_service.dart';
import '../state/app_state.dart';
import '../widgets/money_text.dart';
import '../widgets/pickdrop_incoming_call_banner.dart';
import '../widgets/tracking/direction_hint_card.dart';
import '../widgets/tracking/eta_bottom_sheet.dart';
import '../widgets/tracking/navigation_status_pill.dart';
import '../widgets/tracking/order_progress_timeline.dart';
import '../widgets/tracking/runner_info_card.dart';
import '../widgets/tracking/tracking_map.dart';
import 'pickdrop_call_screen.dart';
import 'pickdrop_chat_screen.dart';

class PickDropTrackingScreen extends StatefulWidget {
  const PickDropTrackingScreen({super.key, required this.order});

  final PickDropOrder order;

  @override
  State<PickDropTrackingScreen> createState() => _PickDropTrackingScreenState();
}

class _PickDropTrackingScreenState extends State<PickDropTrackingScreen> {
  final _realtime = RealtimeTrackingService();
  Timer? _poller;
  Timer? _staleTimer;
  late PickDropOrder _order;
  DriverLiveLocation? _location;
  NavigationRoute _route = const NavigationRoute(points: []);
  DateTime? _lastRouteAt;
  bool _autoFollow = true;
  bool _stale = false;
  bool _loadingRoute = false;
  bool _completing = false;
  String _mode = 'Connecting...';

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
    _staleTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkStale(),
    );
  }

  @override
  void dispose() {
    _poller?.cancel();
    _staleTimer?.cancel();
    _realtime.unsubscribe();
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
    final runner = _location == null
        ? pickup
        : LatLng(_location!.lat.toDouble(), _location!.lng.toDouble());
    final heading = (_location?.heading ?? 0).toDouble();
    final warning = _stale
        ? 'Last updated ${_lastUpdatedLabel(_location?.updatedAt)}'
        : (_route.backendBacked
              ? null
              : 'Route preview until backend route loads');

    return Scaffold(
      body: Stack(
        children: [
          TrackingMap(
            runner: runner,
            pickup: pickup,
            dropoff: dropoff,
            heading: heading,
            activeRoute: _route.points.isEmpty
                ? [runner, _destination]
                : _route.points,
            destination: _destination,
            destinationLabel: _isAfterPickup
                ? 'Runner is heading to your drop-off'
                : 'Runner is heading to pickup',
            completedRoute: _completedRoute(pickup, runner),
            autoFollow: _autoFollow,
            navigationMode: false,
            showRunnerPulse: _location != null && !_stale,
            initialFitAll: true,
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
              child: NavigationStatusPill(
                label: _customerStatusLabel,
                live: _location != null && !_stale,
                leading: Icons.delivery_dining_rounded,
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 74,
            top: 74 + MediaQuery.of(context).padding.top,
            child: DirectionHintCard(
              step: _route.primaryStep,
              loading: _loadingRoute,
              warning: warning,
            ),
          ),
          EtaBottomSheet(
            initialSize: .34,
            minSize: .23,
            maxSize: .72,
            currentTask: _customerTask,
            eta: _route.etaLabel,
            distance: _route.distanceLabel,
            customerName: _order.driverName ?? 'Runner pending',
            orderStatus: _cleanStatus(_order.status),
            onCall: _chatEnabled ? _openCall : null,
            onMessage: _chatEnabled ? _openChat : null,
            onShare: _shareTracking,
            progress: OrderProgressTimeline(
              steps: const [
                'Assigned',
                'Pickup',
                'Picked up',
                'On way',
                'Arriving',
                'Delivered',
              ],
              currentIndex: _customerProgressIndex,
            ),
            runnerInfo: RunnerInfoCard(
              name: _order.driverName ?? 'Finding your runner',
              vehicleType: 'Bike',
              ratingLabel: 'New',
              onCall: _chatEnabled ? _openCall : null,
              onMessage: _chatEnabled ? _openChat : null,
            ),
            extraContent: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AddressSummary(
                  pickupAddress: _order.pickupAddress,
                  dropAddress: _order.dropAddress,
                  itemType: _order.itemType,
                  price: _order.estimatedPrice,
                  mode: _mode,
                ),
                if (_canCustomerComplete) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _completing ? null : _markComplete,
                      icon: _completing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_rounded),
                      label: Text(
                        _completing ? 'Saving...' : 'Mark trip complete',
                      ),
                    ),
                  ),
                ],
              ],
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
    final pickup = LatLng(
      _order.pickupLat.toDouble(),
      _order.pickupLng.toDouble(),
    );
    final dropoff = LatLng(
      _order.dropLat.toDouble(),
      _order.dropLng.toDouble(),
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

  String get _customerTask {
    if (_order.status == 'DELIVERED') return 'Delivered';
    if (_order.status == 'ARRIVED_DROP') return 'Runner is arriving';
    if (_isAfterPickup) return 'On the way to you';
    if (_order.status == 'DRIVER_ASSIGNED') return 'Runner assigned';
    return 'Waiting for runner';
  }

  String get _customerStatusLabel {
    if (_order.status == 'DELIVERED') return 'Delivered';
    if (_order.status == 'ARRIVED_DROP') return 'Arriving soon';
    if (_isAfterPickup) return 'Runner is on the way';
    return 'Runner is moving';
  }

  int get _customerProgressIndex {
    return switch (_order.status) {
      'DRIVER_ASSIGNED' => 0,
      'ARRIVED_PICKUP' => 1,
      'PICKED_UP' => 2,
      'ARRIVED_DROP' => 4,
      'DELIVERED' => 5,
      _ when _isAfterPickup => 3,
      _ => 0,
    };
  }

  List<LatLng> _completedRoute(LatLng pickup, LatLng runner) {
    if (!_isAfterPickup) return const [];
    return [pickup, runner];
  }

  Future<void> _start() async {
    await _refresh();
    if (AppConfig.hasSupabaseRealtime) {
      setState(() => _mode = 'Live via Supabase Realtime');
      await _realtime.subscribePickDrop(
        orderId: _order.id,
        onLocation: (location) {
          if (!mounted) return;
          setState(() {
            _location = location;
            _stale = false;
          });
          unawaited(_loadRoute());
        },
      );
    } else {
      setState(() => _mode = 'Live fallback: polling every 5s');
      _poller = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
    }
  }

  Future<void> _refresh() async {
    final app = context.read<AppState>();
    final nextOrder = await app.refreshPickDropOrder(_order.id);
    final nextLocation = await app.loadPickDropLiveLocation(_order.id);
    if (!mounted) return;
    setState(() {
      _order = nextOrder;
      _location = nextLocation ?? _location;
    });
    await _loadRoute(force: true);
  }

  Future<void> _loadRoute({bool force = false}) async {
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
    final from = _location == null
        ? pickup
        : LatLng(_location!.lat.toDouble(), _location!.lng.toDouble());
    setState(() => _loadingRoute = true);
    final route = await TrackingRouteService(
      context.read<ApiClient>(),
    ).route(orderId: _order.id, from: from, to: _destination, force: force);
    if (!mounted) return;
    setState(() {
      _route = route;
      _lastRouteAt = now;
      _loadingRoute = false;
    });
  }

  void _checkStale() {
    final updatedAt = _location?.updatedAt;
    if (updatedAt == null) return;
    final nextStale =
        DateTime.now().difference(updatedAt) > const Duration(seconds: 30);
    if (nextStale != _stale && mounted) {
      setState(() => _stale = nextStale);
    }
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

  void _shareTracking() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share tracking link placeholder')),
    );
  }

  bool get _canCustomerComplete =>
      !const {'DELIVERED', 'CANCELLED'}.contains(_order.status);

  Future<void> _markComplete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mark trip complete?'),
        content: const Text('This will mark the trip as delivered and paid.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Mark complete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _completing = true);
    final updated = await context.read<AppState>().completeCustomerPickDrop(
      _order.id,
    );
    if (!mounted) return;
    setState(() {
      if (updated != null) _order = updated;
      _completing = false;
    });
    final message = updated == null
        ? context.read<AppState>().error ?? 'Could not complete trip.'
        : 'Trip marked complete.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showMarkerAddress(TrackingMarkerKind kind) {
    final title = switch (kind) {
      TrackingMarkerKind.runner => 'Runner',
      TrackingMarkerKind.pickup => 'Pickup',
      TrackingMarkerKind.dropoff => 'Drop-off',
    };
    final address = switch (kind) {
      TrackingMarkerKind.runner => _order.driverName ?? 'Runner details',
      TrackingMarkerKind.pickup => _order.pickupAddress,
      TrackingMarkerKind.dropoff => _order.dropAddress,
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$title: $address')));
  }

  String _lastUpdatedLabel(DateTime? at) {
    if (at == null) return 'not yet';
    final seconds = DateTime.now().difference(at).inSeconds;
    if (seconds < 60) return '${seconds}s ago';
    return '${(seconds / 60).floor()}m ago';
  }

  String _cleanStatus(String status) {
    final lower = status.replaceAll('_', ' ').toLowerCase();
    return lower.isEmpty ? status : lower[0].toUpperCase() + lower.substring(1);
  }
}

class _AddressSummary extends StatelessWidget {
  const _AddressSummary({
    required this.pickupAddress,
    required this.dropAddress,
    required this.itemType,
    required this.price,
    required this.mode,
  });

  final String pickupAddress;
  final String dropAddress;
  final String itemType;
  final num price;
  final String mode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  itemType,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              MoneyText(
                price,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const Divider(height: 22),
          _AddressLine(
            icon: Icons.storefront_rounded,
            label: 'Pickup',
            value: pickupAddress,
          ),
          const SizedBox(height: 10),
          _AddressLine(
            icon: Icons.home_rounded,
            label: 'Drop-off',
            value: dropAddress,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              mode,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressLine extends StatelessWidget {
  const _AddressLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ],
    );
  }
}
