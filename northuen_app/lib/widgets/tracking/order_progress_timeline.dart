import 'package:flutter/material.dart';

import '../../core/app_theme.dart';

class OrderProgressTimeline extends StatelessWidget {
  const OrderProgressTimeline({
    super.key,
    required this.steps,
    required this.currentIndex,
  });

  final List<String> steps;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            for (var index = 0; index < steps.length; index++) ...[
              Expanded(
                child: _TimelineStep(
                  label: steps[index],
                  complete: index < currentIndex,
                  active: index == currentIndex,
                ),
              ),
              if (index != steps.length - 1)
                Container(
                  width: 18,
                  height: 3,
                  decoration: BoxDecoration(
                    color: index < currentIndex
                        ? NorthuenTheme.gold
                        : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.label,
    required this.complete,
    required this.active,
  });

  final String label;
  final bool complete;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = complete || active
        ? NorthuenTheme.gold
        : const Color(0xFFD1D5DB);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: active ? 18 : 14,
          height: active ? 18 : 14,
          decoration: BoxDecoration(
            color: complete ? NorthuenTheme.gold : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: active ? 4 : 2),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            height: 1.05,
            fontWeight: active ? FontWeight.w900 : FontWeight.w700,
            color: active ? NorthuenTheme.dark : NorthuenTheme.muted,
          ),
        ),
      ],
    );
  }
}
