import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/tenku_button.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  Timer? _timer;
  bool _resent = false;
  int _countdown = 60;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final authProvider = context.read<AuthProvider>();
      await authProvider.checkEmailVerification();
    });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _countdown = 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 1) {
        t.cancel();
        setState(() {
          _resent = false;
          _countdown = 60;
        });
      } else {
        setState(() => _countdown--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  color: AppColors.primary.withOpacity(0.15),
                ),
                child: const Icon(Icons.email_outlined, color: AppColors.primary, size: 48),
              ),
              const SizedBox(height: 32),
              Text('Verify your email',
                  style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                "We've sent a verification link to your email.\nClick the link to activate your account.",
                style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 15, height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                    const SizedBox(width: 12),
                    Text('Checking verification...', style: GoogleFonts.dmSans(color: AppColors.primary, fontSize: 13)),
                  ],
                ),
              ),
              const Spacer(),
              if (!_resent)
                TenkuButton(
                  label: 'Resend Email',
                  variant: ButtonVariant.secondary,
                  onPressed: () async {
                    final success = await authProvider.resendVerificationEmail();
                    if (success && mounted) {
                      setState(() => _resent = true);
                      _startCountdown();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Verification email sent!'), backgroundColor: AppColors.success),
                      );
                    }
                  },
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.bgElevated,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                  child: Text('Resend in ${_countdown}s', textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 15)),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async => authProvider.signOut(),
                child: Text('Sign Out', style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
