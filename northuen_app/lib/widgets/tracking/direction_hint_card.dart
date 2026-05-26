import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../models/navigation_route_model.dart';

class DirectionHintCard extends StatelessWidget {
  const DirectionHintCard({
    super.key,
    required this.step,
    this.loading = false,
    this.warning,
  });

  final NavigationStep step;
  final bool loading;
  final String? warning;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Material(
        key: ValueKey('${step.instruction}-$warning-$loading'),
        color: Colors.white,
        elevation: 12,
        shadowColor: Colors.black.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: NorthuenTheme.gold.withValues(alpha: .20),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_iconFor(step.maneuver), color: NorthuenTheme.dark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      loading ? 'Updating route...' : step.instruction,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    if (warning != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        warning!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFB45309),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ] else if (step.distanceLabel.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        step.distanceLabel,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String maneuver) {
    final lower = maneuver.toLowerCase();
    if (lower.contains('left')) return Icons.turn_left_rounded;
    if (lower.contains('right')) return Icons.turn_right_rounded;
    if (lower.contains('arriv')) return Icons.flag_rounded;
    if (lower.contains('u-turn')) return Icons.u_turn_left_rounded;
    return Icons.straight_rounded;
  }
}
