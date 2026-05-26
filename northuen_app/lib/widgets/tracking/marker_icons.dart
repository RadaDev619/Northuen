import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/app_theme.dart';

class TrackingMarkerSet {
  const TrackingMarkerSet({
    required this.runner,
    required this.pickup,
    required this.dropoff,
  });

  final BitmapDescriptor runner;
  final BitmapDescriptor pickup;
  final BitmapDescriptor dropoff;
}

class RunnerMarker {
  const RunnerMarker._();

  static Future<BitmapDescriptor> icon() => _MarkerPainter.runner();
}

class PickupMarker {
  const PickupMarker._();

  static Future<BitmapDescriptor> icon() => _MarkerPainter.pin(
    icon: Icons.storefront_rounded,
    fill: const Color(0xFF059669),
    accent: const Color(0xFFBBF7D0),
    stroke: Colors.white,
  );
}

class DropoffMarker {
  const DropoffMarker._();

  static Future<BitmapDescriptor> icon() => _MarkerPainter.pin(
    icon: Icons.person_pin_circle_rounded,
    fill: const Color(0xFFE11D48),
    accent: const Color(0xFFFFD1DC),
    stroke: Colors.white,
  );
}

class TrackingMarkerIcons {
  const TrackingMarkerIcons._();

  static Future<TrackingMarkerSet> load() async => TrackingMarkerSet(
    runner: await RunnerMarker.icon(),
    pickup: await PickupMarker.icon(),
    dropoff: await DropoffMarker.icon(),
  );
}

class _MarkerPainter {
  static Future<BitmapDescriptor> runner() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(118, 118);
    final center = Offset(size.width / 2, size.height / 2);
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: .24)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(center.translate(0, 7), 38, shadowPaint);

    final arrowPath = Path()
      ..moveTo(center.dx, 7)
      ..lineTo(center.dx + 14, center.dy - 25)
      ..quadraticBezierTo(
        center.dx,
        center.dy - 18,
        center.dx - 14,
        center.dy - 25,
      )
      ..close();
    canvas.drawPath(arrowPath, Paint()..color = NorthuenTheme.dark);

    canvas.drawCircle(center, 40, Paint()..color = Colors.white);
    canvas.drawCircle(center, 33, Paint()..color = NorthuenTheme.gold);
    canvas.drawCircle(center, 26, Paint()..color = NorthuenTheme.dark);
    canvas.drawCircle(
      center.translate(-11, -11),
      5,
      Paint()..color = Colors.white.withValues(alpha: .28),
    );

    _paintIcon(canvas, Icons.delivery_dining_rounded, center, Colors.white, 38);

    final image = await recorder.endRecording().toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    return _descriptor(image);
  }

  static Future<BitmapDescriptor> pin({
    required IconData icon,
    required Color fill,
    required Color accent,
    required Color stroke,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(104, 120);
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: .24)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(14, 8, 76, 76),
          const Radius.circular(28),
        ),
      )
      ..moveTo(52, 110)
      ..lineTo(31, 75)
      ..lineTo(73, 75)
      ..close();
    canvas.drawPath(path.shift(const Offset(0, 7)), shadowPaint);
    canvas.drawPath(path, Paint()..color = stroke);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(21, 15, 62, 62),
        const Radius.circular(23),
      ),
      Paint()..color = fill,
    );
    canvas.drawCircle(const Offset(34, 28), 7, Paint()..color = accent);
    canvas.drawCircle(
      const Offset(52, 46),
      21,
      Paint()..color = Colors.white.withValues(alpha: .16),
    );
    _paintIcon(canvas, icon, const Offset(52, 46), Colors.white, 32);

    final image = await recorder.endRecording().toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    return _descriptor(image);
  }

  static void _paintIcon(
    Canvas canvas,
    IconData icon,
    Offset center,
    Color color,
    double size,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          color: color,
          fontSize: size,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  static Future<BitmapDescriptor> _descriptor(ui.Image image) async {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(Uint8List.view(bytes!.buffer));
  }
}
