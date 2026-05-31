import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_constants.dart';
import '../../services/call_service.dart';
import '../../widgets/common/tenku_avatar.dart';

class VideoCallScreen extends StatefulWidget {
  final CallModel call;
  final bool isIncoming;
  final String currentUserId;

  const VideoCallScreen({
    super.key,
    required this.call,
    required this.isIncoming,
    required this.currentUserId,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final _callService = CallService();
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isFrontCamera = true;
  bool _callConnected = false;
  int _elapsedSeconds = 0;
  Timer? _durationTimer;
  late StreamSubscription _callSub;

  @override
  void initState() {
    super.initState();
    _listenCallStatus();
    if (widget.isIncoming) _onCallConnected();
  }

  void _listenCallStatus() {
    _callSub = _callService.streamCallStatus(widget.call.id).listen((call) {
      if (call == null) return;
      if (call.status == CallStatus.active && !_callConnected) _onCallConnected();
      else if (call.status == CallStatus.ended || call.status == CallStatus.declined) _endCall(remote: true);
    });
  }

  void _onCallConnected() {
    setState(() => _callConnected = true);
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _elapsedSeconds++));
    // TODO: Initialize Agora RTC engine with video enabled
    // await _agoraEngine.enableVideo()
    // await _agoraEngine.joinChannel(...)
  }

  Future<void> _hangUp() async {
    await _callService.endCall(widget.call.id);
    _endCall(remote: false);
  }

  void _endCall({required bool remote}) {
    _durationTimer?.cancel();
    _callSub.cancel();
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
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Remote video feed placeholder
          Container(
            color: const Color(0xFF101020),
            child: _callConnected
                ? const Center(
                    // TODO: Replace with AgoraVideoView for remote stream
                    child: Icon(Icons.videocam_off_rounded, color: AppColors.textMuted, size: 64),
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TenkuAvatar(imageUrl: _otherAvatar, name: _otherName, size: 100),
                        const SizedBox(height: 20),
                        Text(_otherName,
                            style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        Text(widget.isIncoming ? 'Connecting...' : 'Calling...',
                            style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 16)),
                      ],
                    ),
                  ),
          ),

          // Local video (PiP) placeholder
          Positioned(
            top: 60,
            right: 16,
            child: GestureDetector(
              onTap: () {
                setState(() => _isFrontCamera = !_isFrontCamera);
                // TODO: _agoraEngine.switchCamera()
              },
              child: Container(
                width: 100,
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: _isCameraOff
                    ? const Center(child: Icon(Icons.videocam_off_rounded, color: AppColors.textMuted))
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        // TODO: Replace with AgoraVideoView for local stream
                        child: const ColoredBox(color: Color(0xFF1A1A2E),
                            child: Center(child: Icon(Icons.person_rounded, color: AppColors.textMuted, size: 36))),
                      ),
              ),
            ),
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Text(_otherName,
                        style: GoogleFonts.dmSans(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    if (_callConnected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.success.withOpacity(0.5)),
                        ),
                        child: Text(_durationString,
                            style: GoogleFonts.dmSans(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _VideoControlBtn(
                      icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                      label: _isMuted ? 'Unmute' : 'Mute',
                      active: _isMuted,
                      onTap: () => setState(() => _isMuted = !_isMuted),
                    ),
                    _VideoControlBtn(
                      icon: _isCameraOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                      label: _isCameraOff ? 'Cam On' : 'Cam Off',
                      active: _isCameraOff,
                      onTap: () {
                        setState(() => _isCameraOff = !_isCameraOff);
                        // TODO: _agoraEngine.muteLocalVideoStream(_isCameraOff)
                      },
                    ),
                    // End call button
                    GestureDetector(
                      onTap: _hangUp,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.error,
                          boxShadow: [BoxShadow(color: AppColors.error.withOpacity(0.4), blurRadius: 16)],
                        ),
                        child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 28),
                      ),
                    ),
                    _VideoControlBtn(
                      icon: Icons.flip_camera_ios_rounded,
                      label: 'Flip',
                      onTap: () {
                        setState(() => _isFrontCamera = !_isFrontCamera);
                        // TODO: _agoraEngine.switchCamera()
                      },
                    ),
                    _VideoControlBtn(
                      icon: Icons.screen_share_outlined,
                      label: 'Share',
                      onTap: () {
                        // TODO: _agoraEngine.startScreenCapture(...)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Screen sharing coming soon!')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoControlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _VideoControlBtn({required this.icon, required this.label, this.active = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? AppColors.primary.withOpacity(0.3) : Colors.white.withOpacity(0.15),
              border: Border.all(color: active ? AppColors.primary : Colors.transparent),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }
}
