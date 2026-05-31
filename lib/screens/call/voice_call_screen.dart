import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_constants.dart';
import '../../services/call_service.dart';
import '../../widgets/common/tenku_avatar.dart';

class VoiceCallScreen extends StatefulWidget {
  final CallModel call;
  final bool isIncoming;
  final String currentUserId;

  const VoiceCallScreen({
    super.key,
    required this.call,
    required this.isIncoming,
    required this.currentUserId,
  });

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  final _callService = CallService();
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _callConnected = false;
  int _elapsedSeconds = 0;
  Timer? _durationTimer;
  late StreamSubscription _callSub;

  @override
  void initState() {
    super.initState();
    _listenCallStatus();
    if (!widget.isIncoming) {
      // We're the caller — wait for answer
    } else {
      // Already answered — connect immediately
      _onCallConnected();
    }
  }

  void _listenCallStatus() {
    _callSub = _callService.streamCallStatus(widget.call.id).listen((call) {
      if (call == null) return;
      if (call.status == CallStatus.active && !_callConnected) {
        _onCallConnected();
      } else if (call.status == CallStatus.ended || call.status == CallStatus.declined) {
        _endCall(remote: true);
      }
    });
  }

  void _onCallConnected() {
    setState(() => _callConnected = true);
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsedSeconds++);
    });
    // TODO: Initialize Agora RTC Engine here
    // await _agoraEngine.joinChannel(...)
  }

  Future<void> _hangUp() async {
    await _callService.endCall(widget.call.id);
    _endCall(remote: false);
  }

  void _endCall({required bool remote}) {
    _durationTimer?.cancel();
    _callSub.cancel();
    // TODO: Leave Agora channel here
    if (mounted) context.pop();
  }

  String get _durationString {
    final m = _elapsedSeconds ~/ 60;
    final s = _elapsedSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get _otherName => widget.isIncoming ? widget.call.callerName : widget.call.receiverName;
  String? get _otherAvatar => widget.isIncoming ? widget.call.callerAvatar : widget.call.receiverAvatar;

  @override
  void dispose() {
    _durationTimer?.cancel();
    _callSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A0A1A), Color(0xFF0D1A0D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top info
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
                child: Column(
                  children: [
                    TenkuAvatar(imageUrl: _otherAvatar, name: _otherName, size: 110),
                    const SizedBox(height: 20),
                    Text(_otherName,
                        style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    Text(
                      _callConnected ? _durationString : (widget.isIncoming ? 'Connecting...' : 'Calling...'),
                      style: GoogleFonts.dmSans(
                        color: _callConnected ? AppColors.success : AppColors.textMuted,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              // Controls
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
                child: Column(
                  children: [
                    // Secondary controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ControlButton(
                          icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                          label: _isMuted ? 'Unmute' : 'Mute',
                          active: _isMuted,
                          onTap: () {
                            setState(() => _isMuted = !_isMuted);
                            // TODO: _agoraEngine.muteLocalAudioStream(_isMuted)
                          },
                        ),
                        _ControlButton(
                          icon: _isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                          label: _isSpeakerOn ? 'Speaker' : 'Earpiece',
                          active: _isSpeakerOn,
                          onTap: () {
                            setState(() => _isSpeakerOn = !_isSpeakerOn);
                            // TODO: _agoraEngine.setEnableSpeakerphone(_isSpeakerOn)
                          },
                        ),
                        _ControlButton(
                          icon: Icons.dialpad_rounded,
                          label: 'Keypad',
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    // End call
                    GestureDetector(
                      onTap: _hangUp,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.error,
                          boxShadow: [BoxShadow(color: AppColors.error.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 6))],
                        ),
                        child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 32),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('End Call', style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ControlButton({required this.icon, required this.label, this.active = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? AppColors.primary.withOpacity(0.2) : AppColors.bgElevated,
              border: Border.all(color: active ? AppColors.primary : AppColors.divider),
            ),
            child: Icon(icon, color: active ? AppColors.primary : AppColors.textSecondary, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}
