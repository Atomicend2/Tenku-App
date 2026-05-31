// forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/tenku_text_field.dart';
import '../../widgets/common/tenku_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.sendPasswordReset(_emailCtrl.text.trim());
    if (success && mounted) {
      setState(() => _sent = true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage ?? 'Failed'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: 32),
              if (!_sent) ...[
                Text('Reset Password',
                    style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text("Enter your email and we'll send a reset link",
                    style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 15)),
                const SizedBox(height: 40),
                Form(
                  key: _formKey,
                  child: TenkuTextField(
                    controller: _emailCtrl,
                    label: 'Email',
                    hint: 'your@email.com',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter your email';
                      if (!v.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 32),
                TenkuButton(label: 'Send Reset Link', onPressed: authProvider.isLoading ? null : _send, isLoading: authProvider.isLoading),
              ] else ...[
                const Icon(Icons.mark_email_read_outlined, color: AppColors.accent, size: 64),
                const SizedBox(height: 24),
                Text('Check your email',
                    style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                Text('We sent a password reset link to\n${_emailCtrl.text}',
                    style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 15)),
                const SizedBox(height: 40),
                TenkuButton(label: 'Back to Sign In', onPressed: () => context.go('/auth/login')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
