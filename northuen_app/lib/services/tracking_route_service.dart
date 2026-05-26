import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/navigation_route_model.dart';
import 'api_client.dart';

class TrackingRouteService {
  TrackingRouteService(this.api);

  final ApiClient api;

  Future<NavigationRoute> route({
    required String orderId,
    required LatLng from,
    required LatLng to,
    bool force = false,
  }) async {
    final fallback = [from, to];
    try {
      final json = await api.post('/api/tracking/routes', {
        'orderId': orderId,
        'origin': {'lat': from.latitude, 'lng': from.longitude},
        'destination': {'lat': to.latitude, 'lng': to.longitude},
        'force': force,
      });
      return NavigationRoute.fromBackendJson(json, fallbackPoints: fallback);
    } catch (_) {
      return NavigationRoute.fallback(fallback);
    }
  }
}
