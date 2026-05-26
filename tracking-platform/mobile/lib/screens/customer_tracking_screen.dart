import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/app_config.dart';
import '../services/tracking_api.dart';
import '../utils/polyline.dart';
import '../widgets/tracking_info_card.dart';

class CustomerTrackingScreen extends StatefulWidget {
  const CustomerTrackingScreen({
    super.key,
    required this.orderId,
    required this.pickup,
    required this.dropoff,
  });

  final String orderId;
  final LatLngPoint pickup;
  final LatLngPoint dropoff;

  @override
  State<CustomerTrackingScreen> createState() => _CustomerTrackingScreenState();
}

class _CustomerTrackingScreenState extends State<CustomerTrackingScreen> {
  GoogleMapController? _mapController;
  RealtimeChannel? _locationChannel;
  RealtimeChannel? _routeChannel;
  Timer? _staleTimer;
  LatLng? _runner;
  double _heading = 0;
  String _status = 'waiting';
  DateTime? _lastUpdate;
  bool _stale = false;
  int? _distanceMeters;
  int? _durationSeconds;
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _subscribe());
    _staleTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkStale(),
    );
  }

  @override
  void dispose() {
    _staleTimer?.cancel();
    if (AppConfig.hasSupabase) {
      if (_locationChannel != null) {
        Supabase.instance.client.removeChannel(_locationChannel!);
      }
      if (_routeChannel != null) {
        Supabase.instance.client.removeChannel(_routeChannel!);
      }
    }
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
          title: 'Runner live location',
          status: _status,
          distanceMeters: _distanceMeters,
          durationSeconds: _durationSeconds,
          stale: _stale,
        ),
        if (!AppConfig.hasSupabase)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Material(
              color: Colors.white,
              elevation: 2,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Set SUPABASE_URL and SUPABASE_ANON_KEY to enable realtime.',
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _subscribe() {
    if (!AppConfig.hasSupabase) return;
    final supabase = Supabase.instance.client;
    _locationChannel = supabase.channel('runner-location:${widget.orderId}')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'runner_locations_latest',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'order_id',
          value: widget.orderId,
        ),
        callback: (payload) => _handleLocation(payload.newRecord),
      )
      ..subscribe();

    _routeChannel = supabase.channel('delivery-route:${widget.orderId}')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'delivery_routes',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'order_id',
          value: widget.orderId,
        ),
        callback: (payload) => _handleRoute(payload.newRecord),
      )
      ..subscribe();
  }

  void _handleLocation(Map<String, dynamic> row) {
    final lat = (row['snapped_lat'] ?? row['lat'] as num).toDouble();
    final lng = (row['snapped_lng'] ?? row['lng'] as num).toDouble();
    final next = LatLng(lat, lng);
    setState(() {
      _runner = next;
      _heading = ((row['heading'] ?? 0) as num).toDouble();
      _status = row['status']?.toString() ?? 'tracking';
      _lastUpdate = DateTime.tryParse(row['updated_at']?.toString() ?? '');
      _stale = false;
    });
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: next, zoom: 15, bearing: _heading),
      ),
    );
  }

  void _handleRoute(Map<String, dynamic> row) {
    final encoded = row['encoded_polyline']?.toString();
    if (encoded == null || encoded.isEmpty) return;
    setState(() {
      _routePoints = decodePolyline(encoded);
      _distanceMeters = (row['distance_meters'] as num?)?.toInt();
      _durationSeconds = (row['duration_seconds'] as num?)?.toInt();
    });
  }

  void _checkStale() {
    final lastUpdate = _lastUpdate;
    if (lastUpdate == null) return;
    final nextStale = DateTime.now().difference(lastUpdate) >
        const Duration(seconds: 30);
    if (nextStale != _stale && mounted) {
      setState(() => _stale = nextStale);
    }
  }
}
