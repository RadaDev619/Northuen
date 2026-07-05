import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/config.dart';
import '../core/app_theme.dart';
import '../models/pickdrop_model.dart';
import '../services/realtime_tracking_service.dart';
import '../state/app_state.dart';
import '../widgets/pickdrop_incoming_call_banner.dart';
import 'pickdrop_call_screen.dart';

class PickDropChatScreen extends StatefulWidget {
  const PickDropChatScreen({super.key, required this.order});

  final PickDropOrder order;

  @override
  State<PickDropChatScreen> createState() => _PickDropChatScreenState();
}

class _PickDropChatScreenState extends State<PickDropChatScreen> {
  final _message = TextEditingController();
  final _scrollController = ScrollController();
  final _realtime = RealtimeTrackingService();
  Timer? _poller;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _poller?.cancel();
    _realtime.unsubscribe();
    _message.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final messages = app.pickDropMessages;
    final me = app.user?.id;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick & Drop chat'),
        actions: [
          IconButton(
            tooltip: 'In-app call',
            onPressed: _openCall,
            icon: const Icon(Icons.call_rounded),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () =>
                context.read<AppState>().loadPickDropMessages(widget.order.id),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                color: NorthuenTheme.primary.withValues(alpha: .06),
                child: Text(
                  widget.order.driverName == null
                      ? 'Chat opens after driver accepts.'
                      : 'Chat about pickup, handover, and drop details.',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Expanded(
                child: messages.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 42,
                              color: NorthuenTheme.muted,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'No messages yet',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            SizedBox(height: 4),
                            Text('Start the conversation about this delivery.'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final item = messages[index];
                          return _MessageBubble(
                            message: item,
                            mine: item.senderId == me,
                          );
                        },
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _message,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          decoration: const InputDecoration(
                            hintText: 'Message customer or runner',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: 'Send',
                        onPressed: _sending ? null : _send,
                        icon: _sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          PickDropIncomingCallBanner(order: widget.order, top: 12),
        ],
      ),
    );
  }

  Future<void> _start() async {
    await context.read<AppState>().loadPickDropMessages(widget.order.id);
    _scrollToBottom();
    if (AppConfig.hasSupabaseRealtime) {
      await _realtime.subscribePickDropMessages(
        orderId: widget.order.id,
        onMessage: (message) {
          if (!mounted) return;
          context.read<AppState>().addPickDropMessage(message);
          _scrollToBottom();
        },
      );
    } else {
      _poller = Timer.periodic(const Duration(seconds: 3), (_) async {
        if (!mounted) return;
        await context.read<AppState>().loadPickDropMessages(widget.order.id);
        _scrollToBottom();
      });
    }
  }

  Future<void> _send() async {
    final text = _message.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    final sent = await context.read<AppState>().sendPickDropMessage(
      widget.order.id,
      text,
    );
    if (!mounted) return;
    if (sent != null) {
      _message.clear();
      _scrollToBottom();
    }
    setState(() => _sending = false);
  }

  void _openCall() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PickDropCallScreen(order: widget.order),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.mine});

  final PickDropMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('h:mm a').format(message.createdAt);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * .78,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: mine ? NorthuenTheme.primary : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(8),
              topRight: const Radius.circular(8),
              bottomLeft: Radius.circular(mine ? 8 : 2),
              bottomRight: Radius.circular(mine ? 2 : 8),
            ),
            border: mine ? null : Border.all(color: NorthuenTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mine ? 'You' : message.senderName,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: mine ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message.body,
                style: TextStyle(color: mine ? Colors.white : Colors.black87),
              ),
              const SizedBox(height: 5),
              Text(
                time,
                style: TextStyle(
                  fontSize: 11,
                  color: mine ? Colors.white70 : Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
