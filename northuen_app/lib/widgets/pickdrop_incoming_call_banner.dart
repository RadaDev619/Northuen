import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../models/pickdrop_model.dart';
import '../screens/pickdrop_call_screen.dart';
import '../state/app_state.dart';

class PickDropIncomingCallBanner extends StatefulWidget {
  const PickDropIncomingCallBanner({
    super.key,
    required this.order,
    this.top = 0,
    this.horizontal = 16,
  });

  final PickDropOrder order;
  final double top;
  final double horizontal;

  @override
  State<PickDropIncomingCallBanner> createState() =>
      _PickDropIncomingCallBannerState();
}

class _PickDropIncomingCallBannerState
    extends State<PickDropIncomingCallBanner> {
  Timer? _poller;
  PickDropCallSession? _incoming;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final call = _incoming;
    if (call == null) return const SizedBox.shrink();

    return Positioned(
      left: widget.horizontal,
      right: widget.horizontal,
      top: widget.top,
      child: Material(
        color: NorthuenTheme.dark,
        elevation: 16,
        shadowColor: Colors.black.withValues(alpha: .22),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: NorthuenTheme.gold,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.call_rounded,
                  color: NorthuenTheme.dark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      call.callerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'Incoming Northuen call',
                      style: TextStyle(
                        color: Color(0xFFD1D5DB),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Decline',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: .12),
                  foregroundColor: Colors.white,
                ),
                onPressed: _decline,
                icon: const Icon(Icons.call_end_rounded),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Answer',
                style: IconButton.styleFrom(
                  backgroundColor: NorthuenTheme.success,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _answer(call),
                icon: const Icon(Icons.call_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _start() async {
    await _check();
    _poller = Timer.periodic(const Duration(seconds: 2), (_) => _check());
  }

  Future<void> _check() async {
    if (!mounted) return;
    final app = context.read<AppState>();
    final call = await app.loadActivePickDropCall(widget.order.id);
    final me = app.user?.id;
    if (!mounted) return;
    setState(() {
      _incoming =
          call != null && call.receiverId == me && call.status == 'RINGING'
          ? call
          : null;
    });
  }

  Future<void> _decline() async {
    final call = _incoming;
    if (call == null) return;
    await context.read<AppState>().endPickDropCall(call.id);
    if (mounted) setState(() => _incoming = null);
  }

  void _answer(PickDropCallSession call) {
    setState(() => _incoming = null);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PickDropCallScreen(
          order: widget.order,
          initialCall: call,
          startOutgoing: false,
        ),
      ),
    );
  }
}
