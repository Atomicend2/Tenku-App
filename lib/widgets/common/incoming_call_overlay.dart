import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_constants.dart';
import '../../services/call_service.dart';
import '../../widgets/common/tenku_avatar.dart';

class IncomingCallOverlay extends StatefulWidget {
  final CallModel call;
  final VoidCallback onAnswer;
  final VoidCallback onDecline;

  const IncomingCallOverlay({
    super.key,
    required this.call,
    required this.onAnswer,
    required this.onDecline,
  });

  @override
  State<IncomingCallOverlay> createState() => _IncomingCallOverlayState();
}

class _IncomingCallOverlayState extends State<IncomingCallOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  Timer? _autoDeclineTimer;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _pulseCtrl.repeat(reverse: true);

    // Auto-decline after 30 seconds
    _autoDeclineTimer = Timer(const Duration(seconds: 30), widget.onDecline);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _autoDeclineTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.call.type == CallType.video;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.bgDark,
              isVideo ? AppColors.primary.withOpacity(0.3) : const Color(0xFF0D1A0D),
            ],
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
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
                child: Column(
                  children: [
                    Text(
                      'Incoming ${isVideo ? 'Video' : 'Voice'} Call',
                      style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 16),
                    ),
                    const SizedBox(height: 32),
                    AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, child) => Transform.scale(
                        scale: _pulseAnim.value,
                        child: child,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (isVideo ? AppColors.primary : AppColors.success).withOpacity(0.4),
                              blurRadius: 24,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: TenkuAvatar(
                          imageUrl: widget.call.callerAvatar,
                          name: widget.call.callerName,
                          size: 110,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.call.callerName,
                      style: GoogleFonts.dmSans(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                          color: AppColors.textMuted,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Tenku ${isVideo ? 'Video' : 'Voice'} Call',
                          style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 0, 40, 48),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CallActionButton(
                      icon: Icons.call_end_rounded,
                      color: AppColors.error,
                      label: 'Decline',
                      onTap: widget.onDecline,
                    ),
                    _CallActionButton(
                      icon: isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                      color: AppColors.success,
                      label: 'Answer',
                      onTap: widget.onAnswer,
                    ),
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

class _CallActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _CallActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(height: 10),
        Text(label, style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 13)),
      ],
    );
  }
}
