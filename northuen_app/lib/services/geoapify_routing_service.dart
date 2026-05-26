import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../core/config.dart';

class GeoapifyRoutingService {
  GeoapifyRoutingService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<GeoapifyRoute> route({
    required LatLng from,
    required LatLng to,
  }) async {
    if (AppConfig.hasGoogleMaps) return _googleRoute(from: from, to: to);
    if (!AppConfig.hasGeoapify) return GeoapifyRoute(points: [from, to]);
    final uri = Uri.https('api.geoapify.com', '/v1/routing', {
      'waypoints':
          '${from.latitude},${from.longitude}|${to.latitude},${to.longitude}',
      'mode': 'drive',
      'details': 'instruction_details',
      'apiKey': AppConfig.geoapifyApiKey,
    });
    final response = await _client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return GeoapifyRoute(points: [from, to]);
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final features = (json['features'] as List?) ?? [];
    if (features.isEmpty) return GeoapifyRoute(points: [from, to]);
    final feature = features.first as Map<String, dynamic>;
    final geometry = feature['geometry'] as Map<String, dynamic>?;
    final coordinates = geometry?['coordinates'];
    final points = <LatLng>[];
    _collectCoordinates(coordinates, points);
    final routePoints = points.length < 2 ? [from, to] : points;
    final properties = feature['properties'] as Map<String, dynamic>? ?? {};
    final legs = (properties['legs'] as List?) ?? [];
    final steps = <GeoapifyRouteStep>[];
    num distance = 0;
    num time = 0;

    for (final leg in legs.whereType<Map<String, dynamic>>()) {
      distance += (leg['distance'] as num?) ?? 0;
      time += (leg['time'] as num?) ?? 0;
      for (final step
          in ((leg['steps'] as List?) ?? [])
              .whereType<Map<String, dynamic>>()) {
        final instruction = step['instruction'] as Map<String, dynamic>? ?? {};
        final text =
            (instruction['text'] ??
                    instruction['transition_instruction'] ??
                    'Continue')
                .toString();
        steps.add(
          GeoapifyRouteStep(
            instruction: text,
            type: instruction['type']?.toString() ?? 'None',
            distanceMeters: (step['distance'] as num?) ?? 0,
            timeSeconds: (step['time'] as num?) ?? 0,
          ),
        );
      }
    }

    return GeoapifyRoute(
      points: routePoints,
      steps: steps,
      distanceMeters: distance,
      timeSeconds: time,
    );
  }

  Future<GeoapifyRoute> _googleRoute({
    required LatLng from,
    required LatLng to,
  }) async {
    final uri = Uri.https('maps.googleapis.com', '/maps/api/directions/json', {
      'origin': '${from.latitude},${from.longitude}',
      'destination': '${to.latitude},${to.longitude}',
      'mode': 'driving',
      'key': AppConfig.googleMapsApiKey,
    });
    final response = await _client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return GeoapifyRoute(points: [from, to]);
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['status'] != 'OK') return GeoapifyRoute(points: [from, to]);
    final routes = (json['routes'] as List?) ?? [];
    if (routes.isEmpty) return GeoapifyRoute(points: [from, to]);
    final route = routes.first as Map<String, dynamic>;
    final overview = route['overview_polyline'] as Map<String, dynamic>? ?? {};
    final points = _decodePolyline((overview['points'] ?? '').toString());
    final steps = <GeoapifyRouteStep>[];
    num distance = 0;
    num duration = 0;
    for (final leg
        in ((route['legs'] as List?) ?? []).whereType<Map<String, dynamic>>()) {
      distance +=
          ((leg['distance'] as Map<String, dynamic>?)?['value'] as num?) ?? 0;
      duration +=
          ((leg['duration'] as Map<String, dynamic>?)?['value'] as num?) ?? 0;
      for (final step
          in ((leg['steps'] as List?) ?? [])
              .whereType<Map<String, dynamic>>()) {
        steps.add(
          GeoapifyRouteStep(
            instruction: _stripHtml(
              (step['html_instructions'] ?? 'Continue').toString(),
            ),
            type: (step['maneuver'] ?? 'continue').toString(),
            distanceMeters:
                ((step['distance'] as Map<String, dynamic>?)?['value']
                    as num?) ??
                0,
            timeSeconds:
                ((step['duration'] as Map<String, dynamic>?)?['value']
                    as num?) ??
                0,
          ),
        );
      }
    }
    return GeoapifyRoute(
      points: points.length < 2 ? [from, to] : points,
      steps: steps,
      distanceMeters: distance,
      timeSeconds: duration,
    );
  }

  void _collectCoordinates(dynamic node, List<LatLng> points) {
    if (node is! List || node.isEmpty) return;
    if (node.length >= 2 && node[0] is num && node[1] is num) {
      points.add(
        LatLng((node[1] as num).toDouble(), (node[0] as num).toDouble()),
      );
      return;
    }
    for (final child in node) {
      _collectCoordinates(child, points);
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    var index = 0;
    var lat = 0;
    var lng = 0;
    while (index < encoded.length) {
      var shift = 0;
      var result = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20 && index < encoded.length);
      final dlat = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20 && index < encoded.length);
      final dlng = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
      lng += dlng;
      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  String _stripHtml(String value) => value
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

class GeoapifyRoute {
  GeoapifyRoute({
    required this.points,
    this.steps = const [],
    this.distanceMeters = 0,
    this.timeSeconds = 0,
  });

  final List<LatLng> points;
  final List<GeoapifyRouteStep> steps;
  final num distanceMeters;
  final num timeSeconds;

  String get distanceLabel {
    if (distanceMeters <= 0) return '';
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }
    return '${distanceMeters.round()} m';
  }

  String get etaLabel {
    if (timeSeconds <= 0) return '';
    final minutes = (timeSeconds / 60).ceil();
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '$hours hr' : '$hours hr $rest min';
  }
}

class GeoapifyRouteStep {
  GeoapifyRouteStep({
    required this.instruction,
    required this.type,
    required this.distanceMeters,
    required this.timeSeconds,
  });

  final String instruction;
  final String type;
  final num distanceMeters;
  final num timeSeconds;

  String get distanceLabel {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }
    return '${distanceMeters.round()} m';
  }
}
