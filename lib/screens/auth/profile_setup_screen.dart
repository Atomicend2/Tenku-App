import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/common/tenku_text_field.dart';
import '../../widgets/common/tenku_button.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bioCtrl = TextEditingController();
  final _storageService = StorageService();
  File? _avatarFile;
  bool _uploading = false;

  @override
  void dispose() {
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textMuted, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: Text('Choose from Gallery', style: GoogleFonts.dmSans(color: AppColors.textPrimary)),
              onTap: () async {
                Navigator.pop(context);
                final file = await _storageService.pickImageFromGallery();
                if (file != null) setState(() => _avatarFile = file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
              title: Text('Take a Photo', style: GoogleFonts.dmSans(color: AppColors.textPrimary)),
              onTap: () async {
                Navigator.pop(context);
                final file = await _storageService.pickImageFromCamera();
                if (file != null) setState(() => _avatarFile = file);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _complete() async {
    if (!_formKey.currentState!.validate()) return;
    final authProvider = context.read<AuthProvider>();
    setState(() => _uploading = true);

    String? avatarUrl;
    if (_avatarFile != null && authProvider.currentUser != null) {
      avatarUrl = await _storageService.uploadAvatar(
        userId: authProvider.currentUser!.uid,
        imageFile: _avatarFile!,
      );
    }

    await authProvider.updateProfile(
      bio: _bioCtrl.text.trim(),
      avatarUrl: avatarUrl,
    );

    setState(() => _uploading = false);
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Text('Set up your profile',
                    style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('Add a photo and bio to personalize your account',
                    style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 14),
                    textAlign: TextAlign.center),
                const SizedBox(height: 40),

                // Avatar picker
                GestureDetector(
                  onTap: _pickAvatar,
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                          border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 3),
                          image: _avatarFile != null
                              ? DecorationImage(image: FileImage(_avatarFile!), fit: BoxFit.cover)
                              : null,
                        ),
                        child: _avatarFile == null
                            ? Center(
                                child: Text(
                                  user?.displayName.isNotEmpty == true ? user!.displayName[0].toUpperCase() : 'U',
                                  style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800),
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.bgDark, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _pickAvatar,
                  child: Text('Upload photo', style: GoogleFonts.dmSans(color: AppColors.primary, fontSize: 14)),
                ),
                const SizedBox(height: 32),

                // Info display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline, color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.displayName ?? '', style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                          Text('@${user?.username ?? ''}', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                TenkuTextField(
                  controller: _bioCtrl,
                  label: 'Bio (optional)',
                  hint: 'Tell people about yourself...',
                  prefixIcon: Icons.info_outline,
                  maxLines: 3,
                ),
                const SizedBox(height: 40),

                TenkuButton(
                  label: 'Complete Setup',
                  onPressed: (_uploading || authProvider.isLoading) ? null : _complete,
                  isLoading: _uploading || authProvider.isLoading,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/home'),
                  child: Text('Skip for now', style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 14)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
