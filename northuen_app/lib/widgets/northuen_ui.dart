import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class NorthuenBrandMark extends StatelessWidget {
  const NorthuenBrandMark({super.key, this.size = 44, this.inverse = false});

  final double size;
  final bool inverse;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: inverse ? Colors.white : NorthuenTheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.near_me_rounded,
        size: size * .52,
        color: inverse ? NorthuenTheme.primary : Colors.white,
      ),
    );
  }
}

class NorthuenSectionHeader extends StatelessWidget {
  const NorthuenSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class NorthuenMetricCard extends StatelessWidget {
  const NorthuenMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = NorthuenTheme.primary,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            Text(
              value,
              style: const TextStyle(
                color: NorthuenTheme.ink,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class NorthuenEmptyState extends StatelessWidget {
  const NorthuenEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: NorthuenTheme.primary.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: NorthuenTheme.primary, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class NorthuenErrorBanner extends StatelessWidget {
  const NorthuenErrorBanner({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NorthuenTheme.error.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: NorthuenTheme.error.withValues(alpha: .2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: NorthuenTheme.error),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class NorthuenSkeleton extends StatefulWidget {
  const NorthuenSkeleton({super.key, this.height = 84});

  final double height;

  @override
  State<NorthuenSkeleton> createState() => _NorthuenSkeletonState();
}

class _NorthuenSkeletonState extends State<NorthuenSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: .45, end: .85).animate(_controller),
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
