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
import '../../widgets/common/tenku_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _displayNameCtrl;
  late TextEditingController _bioCtrl;
  final _storageService = StorageService();
  File? _newAvatarFile;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _displayNameCtrl = TextEditingController(text: user?.displayName ?? '');
    _bioCtrl = TextEditingController(text: user?.bio ?? '');
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    setState(() => _loading = true);

    String? avatarUrl;
    if (_newAvatarFile != null) {
      avatarUrl = await _storageService.uploadAvatar(userId: user.uid, imageFile: _newAvatarFile!);
    }

    await context.read<AuthProvider>().updateProfile(
      displayName: _displayNameCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
      avatarUrl: avatarUrl,
    );

    setState(() => _loading = false);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary), onPressed: () => context.pop()),
        title: Text('Edit Profile', style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: Text('Save', style: GoogleFonts.dmSans(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 15)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: GestureDetector(
                onTap: () async {
                  final file = await _storageService.pickImageFromGallery();
                  if (file != null) setState(() => _newAvatarFile = file);
                },
                child: Stack(
                  children: [
                    _newAvatarFile != null
                        ? Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(image: FileImage(_newAvatarFile!), fit: BoxFit.cover),
                              border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 2),
                            ),
                          )
                        : TenkuAvatar(imageUrl: user.avatarUrl, name: user.displayName, size: 90),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.bgDark, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                final file = await _storageService.pickImageFromGallery();
                if (file != null) setState(() => _newAvatarFile = file);
              },
              child: Text('Change Photo', style: GoogleFonts.dmSans(color: AppColors.primary, fontSize: 14)),
            ),
            const SizedBox(height: 24),
            TenkuTextField(
              controller: _displayNameCtrl,
              label: 'Display Name',
              hint: 'Your name',
              prefixIcon: Icons.person_outline,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  const Icon(Icons.alternate_email, color: AppColors.textMuted, size: 20),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Username', style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12)),
                      Text('@${user.username}', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 15)),
                    ],
                  ),
                  const Spacer(),
                  Text('Cannot change', style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TenkuTextField(
              controller: _bioCtrl,
              label: 'Bio',
              hint: 'Tell people about yourself...',
              prefixIcon: Icons.info_outline,
              maxLines: 3,
              maxLength: 150,
            ),
            const SizedBox(height: 40),
            TenkuButton(label: 'Save Changes', onPressed: _loading ? null : _save, isLoading: _loading),
          ],
        ),
      ),
    );
  }
}
