class TrackingPoint {
  TrackingPoint({required this.id, required this.latitude, required this.longitude, required this.createdAt});

  final String id;
  final num latitude;
  final num longitude;
  final DateTime createdAt;

  factory TrackingPoint.fromJson(Map<String, dynamic> json) => TrackingPoint(
        id: json['id'],
        latitude: json['latitude'],
        longitude: json['longitude'],
        createdAt: DateTime.parse(json['createdAt'] ?? json['created_at']),
      );
}
