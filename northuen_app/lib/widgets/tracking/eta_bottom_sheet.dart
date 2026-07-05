import 'package:flutter/material.dart';

import '../../core/app_theme.dart';

class EtaBottomSheet extends StatelessWidget {
  const EtaBottomSheet({
    super.key,
    required this.currentTask,
    required this.eta,
    required this.distance,
    required this.customerName,
    required this.orderStatus,
    this.progress,
    this.runnerInfo,
    this.extraContent,
    this.onCall,
    this.onMessage,
    this.onShare,
    this.onPrimary,
    this.onSecondary,
    this.primaryLabel,
    this.secondaryLabel,
    this.primaryIcon,
    this.secondaryIcon,
    this.initialSize = .28,
    this.minSize = .20,
    this.maxSize = .64,
  });

  final String currentTask;
  final String eta;
  final String distance;
  final String customerName;
  final String orderStatus;
  final Widget? progress;
  final Widget? runnerInfo;
  final Widget? extraContent;
  final VoidCallback? onCall;
  final VoidCallback? onMessage;
  final VoidCallback? onShare;
  final VoidCallback? onPrimary;
  final VoidCallback? onSecondary;
  final String? primaryLabel;
  final String? secondaryLabel;
  final IconData? primaryIcon;
  final IconData? secondaryIcon;
  final double initialSize;
  final double minSize;
  final double maxSize;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: initialSize,
      minChildSize: minSize,
      maxChildSize: maxSize,
      builder: (context, controller) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .16),
                blurRadius: 28,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: ListView(
            controller: controller,
            padding: EdgeInsets.fromLTRB(
              18,
              10,
              18,
              18 + MediaQuery.of(context).padding.bottom,
            ),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentTask,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$customerName - $orderStatus',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _Metric(label: 'ETA', value: eta),
                  const SizedBox(width: 8),
                  _Metric(label: 'Left', value: distance),
                ],
              ),
              if (progress != null) ...[const SizedBox(height: 18), progress!],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onMessage,
                      icon: const Icon(Icons.chat_bubble_rounded),
                      label: const Text('Message'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: onCall,
                      icon: const Icon(Icons.call_rounded),
                      label: const Text('Call'),
                    ),
                  ),
                  if (onShare != null) ...[
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      tooltip: 'Share tracking',
                      onPressed: onShare,
                      icon: const Icon(Icons.ios_share_rounded),
                    ),
                  ],
                ],
              ),
              if (runnerInfo != null) ...[
                const SizedBox(height: 14),
                runnerInfo!,
              ],
              if (primaryLabel != null || secondaryLabel != null) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (secondaryLabel != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onSecondary,
                          icon: Icon(secondaryIcon ?? Icons.stop_rounded),
                          label: Text(secondaryLabel!),
                        ),
                      ),
                    if (secondaryLabel != null && primaryLabel != null)
                      const SizedBox(width: 10),
                    if (primaryLabel != null)
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onPrimary,
                          icon: Icon(primaryIcon ?? Icons.navigation_rounded),
                          label: Text(primaryLabel!),
                        ),
                      ),
                  ],
                ),
              ],
              if (extraContent != null) ...[
                const SizedBox(height: 14),
                extraContent!,
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 64),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: NorthuenTheme.dark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .70),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
