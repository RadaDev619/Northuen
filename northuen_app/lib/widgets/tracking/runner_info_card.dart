import 'package:flutter/material.dart';

import '../../core/app_theme.dart';

class RunnerInfoCard extends StatelessWidget {
  const RunnerInfoCard({
    super.key,
    required this.name,
    this.vehicleType = 'Bike',
    this.ratingLabel = '4.9',
    this.onCall,
    this.onMessage,
  });

  final String name;
  final String vehicleType;
  final String ratingLabel;
  final VoidCallback? onCall;
  final VoidCallback? onMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: NorthuenTheme.dark,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.two_wheeler_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        vehicleType,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.star_rounded,
                      size: 15,
                      color: NorthuenTheme.gold,
                    ),
                    Text(
                      ratingLabel,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Message runner',
            onPressed: onMessage,
            icon: const Icon(Icons.chat_bubble_rounded),
          ),
          const SizedBox(width: 6),
          IconButton.filled(
            tooltip: 'Call runner',
            onPressed: onCall,
            icon: const Icon(Icons.call_rounded),
          ),
        ],
      ),
    );
  }
}
