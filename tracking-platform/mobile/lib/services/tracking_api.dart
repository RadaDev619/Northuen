import 'dart:convert';

import 'package:http/http.dart' as http;

import 'app_config.dart';

class LatLngPoint {
  const LatLngPoint({required this.lat, required this.lng});

  final double lat;
  final double lng;

  Map<String, double> toJson() => {'lat': lat, 'lng': lng};
}

class RouteSnapshot {
  const RouteSnapshot({
    required this.encodedPolyline,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.eta,
  });

  final String encodedPolyline;
  final int distanceMeters;
  final int durationSeconds;
  final DateTime eta;

  factory RouteSnapshot.fromJson(Map<String, dynamic> json) => RouteSnapshot(
        encodedPolyline: json['encodedPolyline'] ?? json['encoded_polyline'],
        distanceMeters: json['distanceMeters'] ?? json['distance_meters'] ?? 0,
        durationSeconds:
            json['durationSeconds'] ?? json['duration_seconds'] ?? 0,
        eta: DateTime.parse(json['eta']),
      );
}

class TrackingApi {
  const TrackingApi();

  Uri _uri(String path) => Uri.parse('${AppConfig.trackingApiBaseUrl}$path');

  Future<void> sendRunnerLocation({
    required String orderId,
    required String runnerId,
    required String status,
    required double lat,
    required double lng,
    double? heading,
    double? speed,
    double? accuracy,
    required DateTime timestamp,
  }) async {
    await _post('/api/tracking/locations', {
      'orderId': orderId,
      'runnerId': runnerId,
      'status': status,
      'lat': lat,
      'lng': lng,
      'heading': heading,
      'speed': speed,
      'accuracy': accuracy,
      'timestamp': timestamp.toUtc().toIso8601String(),
    });
  }

  Future<RouteSnapshot?> requestRoute({
    required String orderId,
    required LatLngPoint origin,
    required LatLngPoint destination,
    bool force = false,
  }) async {
    final json = await _post('/api/tracking/routes', {
      'orderId': orderId,
      'origin': origin.toJson(),
      'destination': destination.toJson(),
      'force': force,
    });
    final route = json['route'];
    if (route == null) return null;
    return RouteSnapshot.fromJson(route);
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final response = await http.post(
      _uri(path),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        decoded is Map && decoded['message'] != null
            ? decoded['message']
            : 'Request failed with ${response.statusCode}',
      );
    }
    return decoded;
  }
}
