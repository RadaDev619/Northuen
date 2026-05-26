import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../models/pickdrop_model.dart';
import '../state/app_state.dart';

class PickDropCallScreen extends StatefulWidget {
  const PickDropCallScreen({
    super.key,
    required this.order,
    this.initialCall,
    this.startOutgoing = true,
  });

  final PickDropOrder order;
  final PickDropCallSession? initialCall;
  final bool startOutgoing;

  @override
  State<PickDropCallScreen> createState() => _PickDropCallScreenState();
}

class _PickDropCallScreenState extends State<PickDropCallScreen> {
  RTCPeerConnection? _peer;
  MediaStream? _localStream;
  PickDropCallSession? _call;
  Timer? _signalPoller;
  Timer? _callPoller;
  final Set<String> _seenSignals = {};
  bool _muted = false;
  bool _speakerOn = true;
  bool _peerReady = false;
  bool _answerAccepted = false;
  bool _offerSent = false;
  bool _ending = false;
  String _status = 'Connecting...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _signalPoller?.cancel();
    _callPoller?.cancel();
    _cleanup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final me = app.user?.id;
    final call = _call;
    final incoming =
        call != null && call.receiverId == me && call.status == 'RINGING';
    final waitingForAnswer =
        call != null && call.callerId == me && call.status == 'RINGING';
    final otherName = call == null
        ? 'Pick & Drop'
        : me == call.callerId
        ? call.receiverName
        : call.callerName;

    return Scaffold(
      backgroundColor: const Color(0xFF101418),
      appBar: AppBar(
        title: const Text('Northuen call'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              const Spacer(),
              _Avatar(name: otherName, ringing: incoming || waitingForAnswer),
              const SizedBox(height: 22),
              Text(
                otherName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                incoming && !_answerAccepted
                    ? 'Incoming Northuen call'
                    : _status,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFD1D5DB),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (incoming && !_answerAccepted)
                _IncomingActions(onAnswer: _answerIncoming, onDecline: _decline)
              else
                _InCallControls(
                  muted: _muted,
                  speakerOn: _speakerOn,
                  ending: _ending,
                  onMute: _toggleMute,
                  onSpeaker: _toggleSpeaker,
                  onEnd: () async {
                    final navigator = Navigator.of(context);
                    await _endCall();
                    if (mounted) navigator.pop();
                  },
                ),
              const SizedBox(height: 26),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _start() async {
    final app = context.read<AppState>();
    final existing =
        widget.initialCall ?? await app.loadActivePickDropCall(widget.order.id);
    PickDropCallSession? call = existing;
    if (call == null && widget.startOutgoing) {
      call = await app.startPickDropCall(widget.order.id);
    }
    if (call == null || !mounted) {
      setState(() => _status = 'No active call');
      return;
    }
    final activeCall = call;
    setState(() {
      _call = activeCall;
      _status = _statusFor(activeCall);
    });

    final me = app.user?.id;
    if (activeCall.callerId == me) {
      await _ensurePeer();
      await _createOffer(activeCall.id);
    }

    _signalPoller = Timer.periodic(
      const Duration(milliseconds: 450),
      (_) => _pollSignals(),
    );
    _callPoller = Timer.periodic(
      const Duration(milliseconds: 900),
      (_) => _refreshCallStatus(),
    );
  }

  Future<void> _answerIncoming() async {
    setState(() {
      _answerAccepted = true;
      _status = 'Answering...';
    });
    await _ensurePeer();
    await _pollSignals();
  }

  Future<void> _decline() async {
    final call = _call;
    if (call != null) {
      await context.read<AppState>().endPickDropCall(call.id);
    }
    await _cleanup();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _ensurePeer() async {
    if (_peerReady) return;
    setState(() => _status = 'Opening microphone...');
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': false,
    });
    await Helper.setSpeakerphoneOn(_speakerOn);
    _peer = await createPeerConnection({
      'sdpSemantics': 'unified-plan',
      'bundlePolicy': 'max-bundle',
      'rtcpMuxPolicy': 'require',
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
        {'urls': 'stun:stun2.l.google.com:19302'},
      ],
    });
    for (final track in _localStream!.getTracks()) {
      await _peer!.addTrack(track, _localStream!);
    }
    _peer!.onIceCandidate = (candidate) async {
      final call = _call;
      if (call == null || candidate.candidate == null) return;
      await context.read<AppState>().sendPickDropCallSignal(
        call.id,
        'candidate',
        jsonEncode({
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        }),
      );
    };
    _peer!.onConnectionState = (state) {
      if (!mounted) return;
      final connected =
          state == RTCPeerConnectionState.RTCPeerConnectionStateConnected;
      setState(() {
        _status = connected
            ? 'Connected'
            : state.name.replaceAll('RTCPeerConnectionState', '');
      });
    };
    _peerReady = true;
  }

  Future<void> _createOffer(String callId) async {
    if (_offerSent || _peer == null) return;
    final app = context.read<AppState>();
    final offer = await _peer!.createOffer({
      'offerToReceiveAudio': 1,
      'offerToReceiveVideo': 0,
      'voiceActivityDetection': true,
    });
    await _peer!.setLocalDescription(offer);
    await app.sendPickDropCallSignal(
      callId,
      'offer',
      jsonEncode({'sdp': offer.sdp, 'type': offer.type}),
    );
    _offerSent = true;
    if (mounted) setState(() => _status = 'Ringing...');
  }

  Future<void> _pollSignals() async {
    final call = _call;
    if (call == null || !mounted) return;
    final app = context.read<AppState>();
    final me = app.user?.id;
    final signals = await app.loadPickDropCallSignals(call.id);
    for (final signal in signals) {
      if (_seenSignals.contains(signal.id) || signal.senderId == me) continue;
      if (signal.type == 'offer' && !_answerAccepted) continue;
      _seenSignals.add(signal.id);
      final payload = jsonDecode(signal.payload) as Map<String, dynamic>;
      if (signal.type == 'offer') {
        await _ensurePeer();
        await _peer!.setRemoteDescription(
          RTCSessionDescription(payload['sdp'], payload['type']),
        );
        final answer = await _peer!.createAnswer({
          'offerToReceiveAudio': 1,
          'offerToReceiveVideo': 0,
          'voiceActivityDetection': true,
        });
        await _peer!.setLocalDescription(answer);
        await app.sendPickDropCallSignal(
          call.id,
          'answer',
          jsonEncode({'sdp': answer.sdp, 'type': answer.type}),
        );
        if (mounted) setState(() => _status = 'Connecting audio...');
      } else if (signal.type == 'answer') {
        if (_peer == null) continue;
        await _peer!.setRemoteDescription(
          RTCSessionDescription(payload['sdp'], payload['type']),
        );
        if (mounted) setState(() => _status = 'Connected');
      } else if (signal.type == 'candidate') {
        if (_peer == null) continue;
        await _peer!.addCandidate(
          RTCIceCandidate(
            payload['candidate'],
            payload['sdpMid'],
            payload['sdpMLineIndex'],
          ),
        );
      }
    }
  }

  Future<void> _refreshCallStatus() async {
    final call = _call;
    if (call == null || !mounted) return;
    final refreshed = await context.read<AppState>().loadActivePickDropCall(
      widget.order.id,
    );
    if (!mounted) return;
    if (refreshed == null || refreshed.status == 'ENDED') {
      setState(() => _status = 'Call ended');
      await _cleanup();
      if (mounted) Navigator.of(context).maybePop();
      return;
    }
    setState(() => _call = refreshed);
  }

  void _toggleMute() {
    final next = !_muted;
    for (final track
        in _localStream?.getAudioTracks() ?? <MediaStreamTrack>[]) {
      track.enabled = !next;
    }
    setState(() => _muted = next);
  }

  Future<void> _toggleSpeaker() async {
    final next = !_speakerOn;
    await Helper.setSpeakerphoneOn(next);
    setState(() => _speakerOn = next);
  }

  Future<void> _endCall() async {
    if (_ending) return;
    setState(() => _ending = true);
    final call = _call;
    if (call != null) await context.read<AppState>().endPickDropCall(call.id);
    await _cleanup();
  }

  Future<void> _cleanup() async {
    _signalPoller?.cancel();
    _callPoller?.cancel();
    for (final track in _localStream?.getTracks() ?? <MediaStreamTrack>[]) {
      await track.stop();
    }
    await _localStream?.dispose();
    await _peer?.close();
    await _peer?.dispose();
    _localStream = null;
    _peer = null;
    _peerReady = false;
  }

  String _statusFor(PickDropCallSession call) {
    final me = context.read<AppState>().user?.id;
    if (call.status == 'ACTIVE') return 'Connected';
    if (call.receiverId == me) return 'Incoming call';
    return 'Calling ${call.receiverName}...';
  }
}

class _Avatar extends StatefulWidget {
  const _Avatar({required this.name, required this.ringing});

  final String name;
  final bool ringing;

  @override
  State<_Avatar> createState() => _AvatarState();
}

class _AvatarState extends State<_Avatar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pulse = widget.ringing ? 1 + (_controller.value * .12) : 1.0;
        return Transform.scale(
          scale: pulse,
          child: CircleAvatar(
            radius: 54,
            backgroundColor: NorthuenTheme.gold,
            child: Text(
              widget.name.characters.first.toUpperCase(),
              style: const TextStyle(
                color: NorthuenTheme.dark,
                fontWeight: FontWeight.w900,
                fontSize: 36,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _IncomingActions extends StatelessWidget {
  const _IncomingActions({required this.onAnswer, required this.onDecline});

  final VoidCallback onAnswer;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CallButton(
          label: 'Decline',
          icon: Icons.call_end_rounded,
          color: const Color(0xFFDC2626),
          onPressed: onDecline,
        ),
        const SizedBox(width: 46),
        _CallButton(
          label: 'Answer',
          icon: Icons.call_rounded,
          color: const Color(0xFF16A34A),
          onPressed: onAnswer,
        ),
      ],
    );
  }
}

class _InCallControls extends StatelessWidget {
  const _InCallControls({
    required this.muted,
    required this.speakerOn,
    required this.ending,
    required this.onMute,
    required this.onSpeaker,
    required this.onEnd,
  });

  final bool muted;
  final bool speakerOn;
  final bool ending;
  final VoidCallback onMute;
  final VoidCallback onSpeaker;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _RoundControl(
          tooltip: muted ? 'Unmute' : 'Mute',
          icon: muted ? Icons.mic_off_rounded : Icons.mic_rounded,
          onPressed: onMute,
        ),
        const SizedBox(width: 22),
        _CallButton(
          label: 'End',
          icon: Icons.call_end_rounded,
          color: const Color(0xFFDC2626),
          onPressed: ending ? null : onEnd,
        ),
        const SizedBox(width: 22),
        _RoundControl(
          tooltip: speakerOn ? 'Speaker on' : 'Speaker off',
          icon: speakerOn ? Icons.volume_up_rounded : Icons.hearing_rounded,
          onPressed: onSpeaker,
        ),
      ],
    );
  }
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton.filledTonal(
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: .12),
          foregroundColor: Colors.white,
          fixedSize: const Size(58, 58),
        ),
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filled(
          style: IconButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            fixedSize: const Size(66, 66),
          ),
          onPressed: onPressed,
          icon: Icon(icon, size: 30),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
