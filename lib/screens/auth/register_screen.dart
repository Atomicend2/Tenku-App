import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/tenku_text_field.dart';
import '../../widgets/common/tenku_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _displayNameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signUp(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      username: _usernameCtrl.text.trim(),
      displayName: _displayNameCtrl.text.trim(),
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Registration failed'),
          backgroundColor: AppColors.error,
        ),
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Back
                IconButton(
                  onPressed: () => context.go('/auth/login'),
                  icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),
                Text(
                  'Create account',
                  style: GoogleFonts.dmSans(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join the Tenku community',
                  style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 15),
                ),
                const SizedBox(height: 36),

                TenkuTextField(
                  controller: _displayNameCtrl,
                  label: 'Display Name',
                  hint: 'How you appear to others',
                  prefixIcon: Icons.person_outline,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter your display name';
                    if (v.trim().length < 2) return 'At least 2 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TenkuTextField(
                  controller: _usernameCtrl,
                  label: 'Username',
                  hint: '@username',
                  prefixIcon: Icons.alternate_email,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter a username';
                    if (v.trim().length < 3) return 'At least 3 characters';
                    if (!RegExp(r'^[a-z0-9._]+$').hasMatch(v.trim())) {
                      return 'Only lowercase letters, numbers, . and _';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TenkuTextField(
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
                const SizedBox(height: 16),

                TenkuTextField(
                  controller: _passwordCtrl,
                  label: 'Password',
                  hint: '••••••••',
                  obscureText: _obscurePassword,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter a password';
                    if (v.length < 8) return 'At least 8 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TenkuTextField(
                  controller: _confirmPasswordCtrl,
                  label: 'Confirm Password',
                  hint: '••••••••',
                  obscureText: _obscureConfirm,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirm your password';
                    if (v != _passwordCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                TenkuButton(
                  label: 'Create Account',
                  onPressed: authProvider.isLoading ? null : _register,
                  isLoading: authProvider.isLoading,
                ),

                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'By signing up, you agree to our Terms of Service\nand Privacy Policy',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 14),
                    ),
                    TextButton(
                      onPressed: () => context.go('/auth/login'),
                      child: Text(
                        'Sign In',
                        style: GoogleFonts.dmSans(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
