import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../core/config.dart';

class PlaceSearchService {
  PlaceSearchService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<PlaceSuggestion>> search(String query) async {
    final text = query.trim();
    if (text.length < 3) return const [];
    if (!AppConfig.hasGeoapify) return _localSuggestions(text);

    try {
      final uri = Uri.https('api.geoapify.com', '/v1/geocode/autocomplete', {
        'text': text,
        'format': 'json',
        'limit': '6',
        'filter': 'countrycode:bt',
        'bias': 'proximity:89.6390,27.4728',
        'apiKey': AppConfig.geoapifyApiKey,
      });
      final response = await _client.get(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _localSuggestions(text);
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final results = (json['results'] as List?) ?? [];
      final suggestions = results
          .whereType<Map<String, dynamic>>()
          .map(_fromGeoapify)
          .whereType<PlaceSuggestion>()
          .toList();
      return suggestions.isEmpty ? _localSuggestions(text) : suggestions;
    } catch (_) {
      return _localSuggestions(text);
    }
  }

  Future<PlaceSuggestion> reverse(LatLng point) async {
    if (AppConfig.hasGoogleMaps) {
      final googlePlace = await _reverseGoogle(point);
      if (googlePlace != null) return googlePlace;
    }
    if (!AppConfig.hasGeoapify) return _fallbackPinnedLocation(point);

    try {
      final uri = Uri.https('api.geoapify.com', '/v1/geocode/reverse', {
        'lat': point.latitude.toString(),
        'lon': point.longitude.toString(),
        'format': 'json',
        'apiKey': AppConfig.geoapifyApiKey,
      });
      final response = await _client.get(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _fallbackPinnedLocation(point);
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final results = (json['results'] as List?) ?? [];
      if (results.isEmpty || results.first is! Map<String, dynamic>) {
        return _fallbackPinnedLocation(point);
      }
      return _fromGeoapifyReverse(results.first as Map<String, dynamic>) ??
          _fallbackPinnedLocation(point);
    } catch (_) {
      return _fallbackPinnedLocation(point);
    }
  }

  void dispose() => _client.close();

  PlaceSuggestion? _fromGeoapify(Map<String, dynamic> json) {
    final lat = (json['lat'] as num?)?.toDouble();
    final lon = (json['lon'] as num?)?.toDouble();
    if (lat == null || lon == null) return null;
    final name =
        (json['name'] ??
                json['street'] ??
                json['suburb'] ??
                json['city'] ??
                'Selected location')
            .toString();
    final formatted = (json['formatted'] ?? '').toString();
    final subtitle = formatted.isEmpty || formatted == name
        ? 'Bhutan'
        : formatted;
    return PlaceSuggestion(
      title: name,
      subtitle: subtitle,
      point: LatLng(lat, lon),
    );
  }

  PlaceSuggestion? _fromGeoapifyReverse(Map<String, dynamic> json) {
    final lat = (json['lat'] as num?)?.toDouble();
    final lon = (json['lon'] as num?)?.toDouble();
    if (lat == null || lon == null) return null;
    final formatted = _clean(json['formatted']);
    if (formatted.isNotEmpty) {
      return PlaceSuggestion(
        title: formatted,
        subtitle: '',
        point: LatLng(lat, lon),
      );
    }

    final line1 = _clean(json['address_line1']);
    final line2 = _clean(json['address_line2']);
    final name = _clean(json['name']);
    final street = _joinNonEmpty([
      _clean(json['housenumber']),
      _clean(json['street']),
    ], ' ');
    final title = _firstNonEmpty([
      line1,
      name,
      street,
      _clean(json['suburb']),
      _clean(json['city']),
      'Selected map location',
    ]);
    final subtitle = _firstNonEmpty([
      line2,
      _clean(json['city']),
      _clean(json['state']),
      _clean(json['country']),
    ]);
    return PlaceSuggestion(
      title: title,
      subtitle: subtitle,
      point: LatLng(lat, lon),
    );
  }

  Future<PlaceSuggestion?> _reverseGoogle(LatLng point) async {
    try {
      final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
        'latlng': '${point.latitude},${point.longitude}',
        'key': AppConfig.googleMapsApiKey,
      });
      final response = await _client.get(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['status'] != 'OK') return null;
      final results = (json['results'] as List?) ?? [];
      if (results.isEmpty || results.first is! Map<String, dynamic>) {
        return null;
      }
      final result = results.first as Map<String, dynamic>;
      final formatted = _clean(result['formatted_address']);
      if (formatted.isEmpty) return null;
      return PlaceSuggestion(title: formatted, subtitle: '', point: point);
    } catch (_) {
      return null;
    }
  }

  List<PlaceSuggestion> _localSuggestions(String query) {
    final needle = query.toLowerCase();
    return _fallbackPlaces
        .where((place) => place.searchText.contains(needle))
        .take(6)
        .toList();
  }

  PlaceSuggestion _fallbackPinnedLocation(LatLng point) {
    var nearest = _fallbackPlaces.first;
    var nearestDistance = double.infinity;
    for (final place in _fallbackPlaces) {
      final distance = _distanceMeters(point, place.point);
      if (distance < nearestDistance) {
        nearest = place;
        nearestDistance = distance;
      }
    }
    return PlaceSuggestion(
      title: nearestDistance <= 1200 ? nearest.title : 'Pinned map location',
      subtitle: nearestDistance <= 1200 ? nearest.subtitle : 'Bhutan',
      point: point,
    );
  }

  String _clean(dynamic value) => (value ?? '').toString().trim();

  String _firstNonEmpty(List<String> values) {
    return values.firstWhere(
      (value) => value.trim().isNotEmpty,
      orElse: () => '',
    );
  }

  String _joinNonEmpty(List<String> values, String separator) {
    return values.where((value) => value.trim().isNotEmpty).join(separator);
  }

  double _distanceMeters(LatLng a, LatLng b) {
    const earthRadiusMeters = 6371000.0;
    final lat1 = _radians(a.latitude);
    final lat2 = _radians(b.latitude);
    final dLat = _radians(b.latitude - a.latitude);
    final dLng = _radians(b.longitude - a.longitude);
    final h =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return earthRadiusMeters * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }

  double _radians(double degrees) => degrees * math.pi / 180;
}

class PlaceSuggestion {
  const PlaceSuggestion({
    required this.title,
    required this.subtitle,
    required this.point,
  });

  final String title;
  final String subtitle;
  final LatLng point;

  String get label => subtitle.isEmpty ? title : '$title, $subtitle';
  String get searchText => '$title $subtitle'.toLowerCase();
}

const _fallbackPlaces = [
  PlaceSuggestion(
    title: 'Clock Tower Square',
    subtitle: 'Norzin Lam, Thimphu',
    point: LatLng(27.4728, 89.6390),
  ),
  PlaceSuggestion(
    title: 'Motithang',
    subtitle: 'Thimphu',
    point: LatLng(27.4850, 89.6250),
  ),
  PlaceSuggestion(
    title: 'Changlimithang Stadium',
    subtitle: 'Thimphu',
    point: LatLng(27.4715, 89.6419),
  ),
  PlaceSuggestion(
    title: 'Memorial Chorten',
    subtitle: 'Chhoten Lam, Thimphu',
    point: LatLng(27.4661, 89.6406),
  ),
  PlaceSuggestion(
    title: 'Tashichho Dzong',
    subtitle: 'Chhagchhen Lam, Thimphu',
    point: LatLng(27.4893, 89.6350),
  ),
  PlaceSuggestion(
    title: 'Lungtenzampa',
    subtitle: 'Thimphu',
    point: LatLng(27.4596, 89.6415),
  ),
  PlaceSuggestion(
    title: 'Olakha',
    subtitle: 'Thimphu',
    point: LatLng(27.4374, 89.6534),
  ),
  PlaceSuggestion(
    title: 'Babesa',
    subtitle: 'Thimphu',
    point: LatLng(27.4208, 89.6501),
  ),
  PlaceSuggestion(
    title: 'Changzamtog',
    subtitle: 'Thimphu',
    point: LatLng(27.4562, 89.6437),
  ),
  PlaceSuggestion(
    title: 'Dechencholing',
    subtitle: 'Thimphu',
    point: LatLng(27.5180, 89.6383),
  ),
  PlaceSuggestion(
    title: 'Taba',
    subtitle: 'Thimphu',
    point: LatLng(27.5096, 89.6385),
  ),
  PlaceSuggestion(
    title: 'Kawangjangsa',
    subtitle: 'Thimphu',
    point: LatLng(27.4861, 89.6295),
  ),
];
