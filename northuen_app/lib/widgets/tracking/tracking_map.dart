import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/app_theme.dart';
import 'marker_icons.dart';
import 'recenter_button.dart';

enum TrackingMarkerKind { runner, pickup, dropoff }

class TrackingMap extends StatefulWidget {
  const TrackingMap({
    super.key,
    required this.runner,
    required this.pickup,
    required this.dropoff,
    required this.heading,
    required this.activeRoute,
    required this.destination,
    required this.destinationLabel,
    this.completedRoute = const [],
    this.autoFollow = true,
    this.navigationMode = false,
    this.showRunnerPulse = false,
    this.onAutoFollowChanged,
    this.onRecenter,
    this.onMarkerTap,
    this.initialFitAll = false,
  });

  final LatLng runner;
  final LatLng pickup;
  final LatLng dropoff;
  final double heading;
  final List<LatLng> activeRoute;
  final LatLng destination;
  final String destinationLabel;
  final List<LatLng> completedRoute;
  final bool autoFollow;
  final bool navigationMode;
  final bool showRunnerPulse;
  final ValueChanged<bool>? onAutoFollowChanged;
  final VoidCallback? onRecenter;
  final ValueChanged<TrackingMarkerKind>? onMarkerTap;
  final bool initialFitAll;

  @override
  State<TrackingMap> createState() => _TrackingMapState();
}

class _TrackingMapState extends State<TrackingMap>
    with TickerProviderStateMixin {
  GoogleMapController? _controller;
  TrackingMarkerSet? _icons;
  late LatLng _animatedRunner = widget.runner;
  late final AnimationController _runnerController =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 950),
      )..addListener(() {
        setState(() {
          _animatedRunner = _runnerTween.evaluate(_runnerController);
        });
      });
  late final AnimationController _pulseController =
      AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1500),
        )
        ..addListener(() {
          if (widget.showRunnerPulse && mounted) setState(() {});
        })
        ..repeat();
  late LatLngTween _runnerTween = LatLngTween(
    begin: widget.runner,
    end: widget.runner,
  );
  bool _mapReady = false;
  bool _suppressCameraStarted = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadIcons());
  }

  @override
  void didUpdateWidget(covariant TrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.runner != widget.runner) {
      _runnerTween = LatLngTween(begin: _animatedRunner, end: widget.runner);
      _runnerController
        ..reset()
        ..forward();
    }
    if (_mapReady &&
        widget.autoFollow &&
        (oldWidget.runner != widget.runner ||
            oldWidget.heading != widget.heading ||
            oldWidget.navigationMode != widget.navigationMode)) {
      _moveCameraForMode();
    }
  }

  @override
  void dispose() {
    _runnerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icons = _icons;
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: widget.runner,
            zoom: widget.navigationMode ? 17 : 14,
            tilt: widget.navigationMode ? 55 : 0,
            bearing: widget.navigationMode ? widget.heading : 0,
          ),
          onMapCreated: _handleMapCreated,
          myLocationButtonEnabled: false,
          compassEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          rotateGesturesEnabled: true,
          tiltGesturesEnabled: true,
          onCameraMoveStarted: _handleCameraMoveStarted,
          circles: {
            if (widget.showRunnerPulse)
              Circle(
                circleId: const CircleId('runner_pulse'),
                center: _animatedRunner,
                radius: 28 + (_pulseController.value * 44),
                strokeWidth: 2,
                strokeColor: NorthuenTheme.gold.withValues(
                  alpha: (1 - _pulseController.value) * .50,
                ),
                fillColor: NorthuenTheme.gold.withValues(
                  alpha: (1 - _pulseController.value) * .12,
                ),
              ),
            Circle(
              circleId: const CircleId('active_destination'),
              center: widget.destination,
              radius: 42,
              strokeWidth: 3,
              strokeColor: const Color(0xFF2563EB).withValues(alpha: .70),
              fillColor: const Color(0xFF2563EB).withValues(alpha: .10),
            ),
          },
          polylines: {
            if (widget.completedRoute.length > 1)
              Polyline(
                polylineId: const PolylineId('completed_route'),
                points: widget.completedRoute,
                width: 6,
                color: const Color(0xFF9CA3AF),
                patterns: [PatternItem.dash(18), PatternItem.gap(10)],
              ),
            if (widget.activeRoute.length > 1)
              Polyline(
                polylineId: const PolylineId('active_route'),
                points: widget.activeRoute,
                width: 7,
                color: const Color(0xFF2563EB),
                jointType: JointType.round,
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
              ),
          },
          markers: {
            Marker(
              markerId: const MarkerId('pickup'),
              position: widget.pickup,
              icon: icons?.pickup ?? BitmapDescriptor.defaultMarker,
              anchor: const Offset(.5, .92),
              infoWindow: const InfoWindow(title: 'Pickup'),
              onTap: () => widget.onMarkerTap?.call(TrackingMarkerKind.pickup),
            ),
            Marker(
              markerId: const MarkerId('dropoff'),
              position: widget.dropoff,
              icon:
                  icons?.dropoff ??
                  BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed,
                  ),
              anchor: const Offset(.5, .92),
              infoWindow: const InfoWindow(title: 'Drop-off'),
              onTap: () => widget.onMarkerTap?.call(TrackingMarkerKind.dropoff),
            ),
            Marker(
              markerId: const MarkerId('runner'),
              position: _animatedRunner,
              icon:
                  icons?.runner ??
                  BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueYellow,
                  ),
              rotation: widget.heading,
              flat: true,
              anchor: const Offset(.5, .5),
              infoWindow: const InfoWindow(title: 'Runner'),
              onTap: () => widget.onMarkerTap?.call(TrackingMarkerKind.runner),
            ),
          },
        ),
        Positioned(
          right: 14,
          top: 112 + MediaQuery.of(context).padding.top,
          child: Column(
            children: [
              RecenterButton(
                tooltip: 'Compass',
                icon: Icons.explore_rounded,
                onPressed: _northUp,
              ),
              const SizedBox(height: 10),
              AnimatedScale(
                scale: widget.autoFollow ? .88 : 1,
                duration: const Duration(milliseconds: 180),
                child: RecenterButton(
                  onPressed: _recenter,
                  icon: widget.autoFollow
                      ? Icons.gps_fixed_rounded
                      : Icons.my_location_rounded,
                ),
              ),
              const SizedBox(height: 10),
              RecenterButton(
                tooltip: 'Zoom in',
                icon: Icons.add_rounded,
                onPressed: () =>
                    _controller?.animateCamera(CameraUpdate.zoomIn()),
              ),
              const SizedBox(height: 10),
              RecenterButton(
                tooltip: 'Zoom out',
                icon: Icons.remove_rounded,
                onPressed: () =>
                    _controller?.animateCamera(CameraUpdate.zoomOut()),
              ),
            ],
          ),
        ),
        Positioned(
          left: 16,
          right: 82,
          bottom: 238 + MediaQuery.of(context).padding.bottom,
          child: _DestinationChip(label: widget.destinationLabel),
        ),
      ],
    );
  }

  Future<void> _loadIcons() async {
    final icons = await TrackingMarkerIcons.load();
    if (mounted) setState(() => _icons = icons);
  }

  void _handleMapCreated(GoogleMapController controller) {
    _controller = controller;
    _mapReady = true;
    if (widget.initialFitAll) {
      _fitAll();
    } else {
      _animateFollow();
    }
  }

  void _handleCameraMoveStarted() {
    if (_suppressCameraStarted) return;
    if (widget.autoFollow) widget.onAutoFollowChanged?.call(false);
  }

  void _recenter() {
    widget.onAutoFollowChanged?.call(true);
    widget.onRecenter?.call();
    _moveCameraForMode();
  }

  void _northUp() {
    _animateCamera(
      CameraPosition(
        target: _animatedRunner,
        zoom: widget.navigationMode ? 16 : 14,
        tilt: 0,
        bearing: 0,
      ),
    );
  }

  void _animateFollow() {
    _animateCamera(
      CameraPosition(
        target: _animatedRunner,
        zoom: widget.navigationMode ? 17 : 15,
        tilt: widget.navigationMode ? 55 : 0,
        bearing: widget.navigationMode ? widget.heading : 0,
      ),
    );
  }

  void _moveCameraForMode() {
    if (widget.initialFitAll && !widget.navigationMode) {
      _fitAll();
    } else {
      _animateFollow();
    }
  }

  void _fitAll() {
    final points = {
      widget.runner,
      widget.pickup,
      widget.dropoff,
      widget.destination,
      ...widget.activeRoute,
    }.toList();
    final bounds = _bounds(points);
    _suppressCameraStarted = true;
    final controller = _controller;
    if (controller == null) {
      _suppressCameraStarted = false;
      return;
    }
    controller
        .animateCamera(CameraUpdate.newLatLngBounds(bounds, 72))
        .whenComplete(() => _suppressCameraStarted = false);
  }

  void _animateCamera(CameraPosition position) {
    _suppressCameraStarted = true;
    final controller = _controller;
    if (controller == null) {
      _suppressCameraStarted = false;
      return;
    }
    controller
        .animateCamera(CameraUpdate.newCameraPosition(position))
        .whenComplete(() => _suppressCameraStarted = false);
  }

  LatLngBounds _bounds(List<LatLng> points) {
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;
    for (final point in points.skip(1)) {
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLng = point.longitude < minLng ? point.longitude : minLng;
      maxLng = point.longitude > maxLng ? point.longitude : maxLng;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}

class _DestinationChip extends StatelessWidget {
  const _DestinationChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.white,
        elevation: 10,
        shadowColor: Colors.black.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.flag_rounded,
                  color: Colors.white,
                  size: 15,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: NorthuenTheme.dark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LatLngTween extends Tween<LatLng> {
  LatLngTween({required super.begin, required super.end});

  @override
  LatLng lerp(double t) {
    final start = begin!;
    final finish = end!;
    return LatLng(
      start.latitude + (finish.latitude - start.latitude) * t,
      start.longitude + (finish.longitude - start.longitude) * t,
    );
  }
}
