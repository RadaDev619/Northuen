import 'package:flutter/material.dart';

class TrackingInfoCard extends StatelessWidget {
  const TrackingInfoCard({
    super.key,
    required this.title,
    required this.status,
    this.distanceMeters,
    this.durationSeconds,
    this.stale = false,
  });

  final String title;
  final String status;
  final int? distanceMeters;
  final int? durationSeconds;
  final bool stale;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 18,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.white,
        elevation: 3,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    _duration(durationSeconds),
                    style: const TextStyle(
                      color: Color(0xff166534),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    _distance(distanceMeters),
                    style: const TextStyle(
                      color: Color(0xff166534),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    status.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              if (stale) ...[
                const SizedBox(height: 8),
                const Text(
                  'Runner location updating...',
                  style: TextStyle(
                    color: Color(0xffb45309),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _duration(int? seconds) {
    if (seconds == null) return '--';
    final minutes = (seconds / 60).round().clamp(1, 999);
    return '$minutes min';
  }

  static String _distance(int? meters) {
    if (meters == null) return '--';
    if (meters < 1000) return '$meters m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}
