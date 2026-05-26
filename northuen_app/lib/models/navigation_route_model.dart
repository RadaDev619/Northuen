import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

class NavigationRoute {
  const NavigationRoute({
    required this.points,
    this.steps = const [],
    this.distanceMeters = 0,
    this.durationSeconds = 0,
    this.eta,
    this.backendBacked = false,
  });

  final List<LatLng> points;
  final List<NavigationStep> steps;
  final int distanceMeters;
  final int durationSeconds;
  final DateTime? eta;
  final bool backendBacked;

  String get distanceLabel {
    if (distanceMeters <= 0) return '--';
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }
    return '$distanceMeters m';
  }

  String get etaLabel {
    if (durationSeconds <= 0) return '--';
    final minutes = (durationSeconds / 60).ceil();
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '$hours hr' : '$hours hr $rest min';
  }

  NavigationStep get primaryStep {
    if (steps.isNotEmpty) return steps.first;
    return const NavigationStep(
      instruction: 'Continue toward destination',
      maneuver: 'continue',
      distanceMeters: 0,
      durationSeconds: 0,
    );
  }

  factory NavigationRoute.fromBackendJson(
    dynamic json, {
    required List<LatLng> fallbackPoints,
  }) {
    final data = json is Map<String, dynamic> && json['route'] != null
        ? json['route']
        : json;
    if (data is! Map<String, dynamic>) {
      return NavigationRoute.fallback(fallbackPoints);
    }

    final encoded =
        data['encodedPolyline'] ??
        data['encoded_polyline'] ??
        data['polyline'] ??
        data['overviewPolyline'];
    final points = encoded is String && encoded.isNotEmpty
        ? decodeEncodedPolyline(encoded)
        : _pointsFromJson(data['points']);

    final rawSteps = data['steps'];
    final steps = rawSteps is List
        ? rawSteps
              .whereType<Map>()
              .map((item) => NavigationStep.fromJson(item))
              .toList()
        : const <NavigationStep>[];

    return NavigationRoute(
      points: points.length > 1 ? points : fallbackPoints,
      steps: steps,
      distanceMeters: _asInt(data['distanceMeters'] ?? data['distance_meters']),
      durationSeconds: _asInt(
        data['durationSeconds'] ?? data['duration_seconds'],
      ),
      eta: DateTime.tryParse((data['eta'] ?? '').toString()),
      backendBacked: true,
    );
  }

  factory NavigationRoute.fallback(List<LatLng> points) {
    final distance = points.length < 2
        ? 0
        : _distanceMeters(points.first, points.last).round();
    return NavigationRoute(
      points: points,
      distanceMeters: distance,
      durationSeconds: distance == 0 ? 0 : (distance / 7.5).round(),
      steps: const [
        NavigationStep(
          instruction: 'Continue toward destination',
          maneuver: 'continue',
          distanceMeters: 0,
          durationSeconds: 0,
        ),
      ],
    );
  }
}

class NavigationStep {
  const NavigationStep({
    required this.instruction,
    required this.maneuver,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final String instruction;
  final String maneuver;
  final int distanceMeters;
  final int durationSeconds;

  String get distanceLabel {
    if (distanceMeters <= 0) return '';
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }
    return '$distanceMeters m';
  }

  factory NavigationStep.fromJson(Map<dynamic, dynamic> json) {
    final instruction =
        json['instruction'] ??
        json['instructions'] ??
        json['text'] ??
        json['localizedValues']?['distance']?['text'] ??
        'Continue';
    return NavigationStep(
      instruction: instruction.toString(),
      maneuver: (json['maneuver'] ?? json['type'] ?? 'continue').toString(),
      distanceMeters: _asInt(json['distanceMeters'] ?? json['distance_meters']),
      durationSeconds: _asInt(
        json['durationSeconds'] ?? json['duration_seconds'],
      ),
    );
  }
}

List<LatLng> decodeEncodedPolyline(String encoded) {
  var index = 0;
  var lat = 0;
  var lng = 0;
  final coordinates = <LatLng>[];

  while (index < encoded.length) {
    final latChunk = _decodeChunk(encoded, index);
    index = latChunk.nextIndex;
    lat += latChunk.value;

    final lngChunk = _decodeChunk(encoded, index);
    index = lngChunk.nextIndex;
    lng += lngChunk.value;

    coordinates.add(LatLng(lat / 1e5, lng / 1e5));
  }

  return coordinates;
}

({int nextIndex, int value}) _decodeChunk(String encoded, int startIndex) {
  var index = startIndex;
  var result = 0;
  var shift = 0;
  var byte = 0;

  do {
    byte = encoded.codeUnitAt(index++) - 63;
    result |= (byte & 0x1f) << shift;
    shift += 5;
  } while (byte >= 0x20 && index < encoded.length);

  return (nextIndex: index, value: result.isOdd ? ~(result >> 1) : result >> 1);
}

List<LatLng> _pointsFromJson(dynamic json) {
  if (json is! List) return const [];
  return json.whereType<Map>().map((point) {
    final lat = point['lat'] ?? point['latitude'];
    final lng = point['lng'] ?? point['longitude'];
    return LatLng((lat as num).toDouble(), (lng as num).toDouble());
  }).toList();
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _distanceMeters(LatLng a, LatLng b) {
  const earthRadius = 6371000.0;
  final dLat = _rad(b.latitude - a.latitude);
  final dLng = _rad(b.longitude - a.longitude);
  final lat1 = _rad(a.latitude);
  final lat2 = _rad(b.latitude);
  final h =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1) * math.cos(lat2) * math.sin(dLng / 2) * math.sin(dLng / 2);
  return earthRadius * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
}

double _rad(double degrees) => degrees * math.pi / 180;
