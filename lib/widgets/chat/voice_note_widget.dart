import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_constants.dart';

// ─── Voice Recorder Button ───────────────────────────────────
// Hold to record, release to send, slide left to cancel.
// Integration: flutter_sound FlutterSoundRecorder for actual recording.

class VoiceNoteRecorder extends StatefulWidget {
  final Function(String path, int durationSec, List<double> waveform) onSend;
  final VoidCallback onCancel;

  const VoiceNoteRecorder({super.key, required this.onSend, required this.onCancel});

  @override
  State<VoiceNoteRecorder> createState() => _VoiceNoteRecorderState();
}

class _VoiceNoteRecorderState extends State<VoiceNoteRecorder>
    with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  bool _isCancelling = false;
  int _seconds = 0;
  Timer? _timer;
  double _dragX = 0;
  final List<double> _waveform = [];
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  Timer? _waveformTimer;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  void _startRecording() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isRecording = true;
      _isCancelling = false;
      _seconds = 0;
      _waveform.clear();
      _dragX = 0;
    });
    _pulseCtrl.repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _seconds++);
      if (_seconds >= 120) _stopAndSend(); // Max 2 min
    });

    // Simulate waveform (replace with real amplitude from flutter_sound)
    _waveformTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      setState(() {
        _waveform.add(0.2 + Random().nextDouble() * 0.8);
        if (_waveform.length > 60) _waveform.removeAt(0);
      });
    });

    // TODO: Start flutter_sound recording
    // await _recorder.openRecorder();
    // await _recorder.startRecorder(toFile: _localPath, codec: Codec.aacADTS);
  }

  void _stopAndSend() {
    if (!_isRecording) return;
    HapticFeedback.lightImpact();
    _timer?.cancel();
    _waveformTimer?.cancel();
    _pulseCtrl.stop();

    final dur = _seconds;
    final wf = List<double>.from(_waveform);

    setState(() => _isRecording = false);

    // TODO: Stop real recording:
    // final path = await _recorder.stopRecorder();
    // widget.onSend(path!, dur, wf);

    // For now, send with placeholder path
    widget.onSend('/tmp/placeholder_voice.aac', dur, wf);
  }

  void _cancelRecording() {
    HapticFeedback.heavyImpact();
    _timer?.cancel();
    _waveformTimer?.cancel();
    _pulseCtrl.stop();
    setState(() { _isRecording = false; _isCancelling = false; });
    widget.onCancel();
    // TODO: await _recorder.stopRecorder(); then delete file
  }

  @override
  void dispose() {
    _timer?.cancel();
    _waveformTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  String get _timeStr {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isRecording) {
      return _buildRecordingBar();
    }
    return _buildMicButton();
  }

  Widget _buildMicButton() {
    return GestureDetector(
      onLongPressStart: (_) => _startRecording(),
      onLongPressEnd: (_) => _stopAndSend(),
      onLongPressMoveUpdate: (d) {
        setState(() => _dragX = d.offsetFromOrigin.dx);
        if (_dragX < -80) {
          setState(() => _isCancelling = true);
        } else {
          setState(() => _isCancelling = false);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.bgElevated,
          border: Border.all(color: AppColors.divider),
        ),
        child: const Icon(Icons.mic_rounded, color: AppColors.textSecondary, size: 22),
      ),
    );
  }

  Widget _buildRecordingBar() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _isCancelling ? AppColors.error : AppColors.primary.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Transform.scale(
              scale: _pulseAnim.value,
              child: Container(
                width: 10, height: 10,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.error),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _timeStr,
            style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 10),

          // Mini waveform
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _waveform.reversed.take(20).map((amp) {
                return Container(
                  width: 3,
                  height: 4 + (amp * 24),
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: _isCancelling
                        ? AppColors.error.withOpacity(0.7)
                        : AppColors.primary.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }).toList(),
            ),
          ),

          // Slide to cancel hint
          if (!_isCancelling)
            Text(
              '< Cancel',
              style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12),
            )
          else
            Text(
              'Release to cancel',
              style: GoogleFonts.dmSans(color: AppColors.error, fontSize: 12),
            ),
          const SizedBox(width: 12),

          // Cancel button
          GestureDetector(
            onTap: _cancelRecording,
            child: Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.error),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 8),

          // Send button
          GestureDetector(
            onTap: _stopAndSend,
            child: Container(
              width: 36, height: 36,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.success),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ─── Voice Note Playback Bubble ──────────────────────────────

class VoiceNoteBubble extends StatefulWidget {
  final String audioUrl;
  final int durationSeconds;
  final List<double> waveform;
  final bool isMe;

  const VoiceNoteBubble({
    super.key,
    required this.audioUrl,
    required this.durationSeconds,
    this.waveform = const [],
    required this.isMe,
  });

  @override
  State<VoiceNoteBubble> createState() => _VoiceNoteBubbleState();
}

class _VoiceNoteBubbleState extends State<VoiceNoteBubble> {
  bool _isPlaying = false;
  double _progress = 0;
  int _currentSecond = 0;
  Timer? _timer;

  void _togglePlayback() {
    if (_isPlaying) {
      _timer?.cancel();
      setState(() => _isPlaying = false);
      // TODO: await _player.pausePlayer();
    } else {
      setState(() => _isPlaying = true);
      // TODO: await _player.startPlayer(fromURI: widget.audioUrl, ...)

      // Simulate playback progress
      _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
        final total = widget.durationSeconds;
        setState(() {
          _progress = (_currentSecond / total).clamp(0.0, 1.0);
          _currentSecond++;
          if (_currentSecond > total) {
            _isPlaying = false;
            _currentSecond = 0;
            _progress = 0;
            t.cancel();
          }
        });
      });
    }
  }

  String get _timeStr {
    final s = _isPlaying ? _currentSecond : widget.durationSeconds;
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barColor = widget.isMe ? Colors.white.withOpacity(0.7) : AppColors.primary;
    final activeColor = widget.isMe ? Colors.white : AppColors.primary;
    final bgColor = widget.isMe ? AppColors.myBubble : AppColors.theirBubble;

    final waveform = widget.waveform.isNotEmpty
        ? widget.waveform
        : List.generate(30, (i) => 0.2 + (sin(i * 0.5).abs() * 0.6));

    return Container(
      width: 240,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: widget.isMe
            ? [BoxShadow(color: AppColors.primary.withOpacity(0.15), blurRadius: 8)]
            : null,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _togglePlayback,
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activeColor.withOpacity(0.2),
                border: Border.all(color: activeColor.withOpacity(0.5)),
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: widget.isMe ? Colors.white : AppColors.primary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Waveform bars
                SizedBox(
                  height: 28,
                  child: LayoutBuilder(
                    builder: (_, constraints) {
                      final barCount = min(30, waveform.length);
                      final barWidth = (constraints.maxWidth / barCount) - 1.5;
                      return Row(
                        children: List.generate(barCount, (i) {
                          final idx = (i / barCount * waveform.length).floor().clamp(0, waveform.length - 1);
                          final amp = waveform[idx];
                          final isActive = _isPlaying && i / barCount < _progress;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 0.75),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 50),
                              width: barWidth,
                              height: 4 + (amp * 22),
                              decoration: BoxDecoration(
                                color: isActive ? activeColor : barColor.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _timeStr,
                  style: GoogleFonts.dmSans(
                    color: widget.isMe ? Colors.white70 : AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
