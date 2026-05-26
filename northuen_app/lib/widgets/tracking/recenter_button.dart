import 'package:flutter/material.dart';

class RecenterButton extends StatelessWidget {
  const RecenterButton({
    super.key,
    required this.onPressed,
    this.icon = Icons.my_location_rounded,
    this.tooltip = 'Recenter',
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        elevation: 10,
        shadowColor: Colors.black.withValues(alpha: .16),
        shape: const CircleBorder(),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          color: const Color(0xFF111827),
        ),
      ),
    );
  }
}
