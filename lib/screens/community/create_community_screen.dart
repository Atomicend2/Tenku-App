import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/community_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/common/tenku_text_field.dart';
import '../../widgets/common/tenku_button.dart';
import '../../widgets/common/tenku_avatar.dart';

class CreateCommunityScreen extends StatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _communityService = CommunityService();
  final _storageService = StorageService();
  File? _iconFile;
  bool _isPublic = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    setState(() => _loading = true);

    try {
      final community = await _communityService.createCommunity(
        name: _nameCtrl.text.trim(),
        ownerId: user.uid,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        isPublic: _isPublic,
      );

      if (_iconFile != null) {
        final iconUrl = await _storageService.uploadCommunityIcon(
          communityId: community.id,
          imageFile: _iconFile!,
        );
        if (iconUrl != null) {
          // Update community with icon url
        }
      }

      setState(() => _loading = false);
      if (mounted) {
        context.pop();
        context.push('/community/${community.id}');
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        leading: IconButton(icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary), onPressed: () => context.pop()),
        title: Text('Create Community', style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Icon picker
              GestureDetector(
                onTap: () async {
                  final file = await _storageService.pickImageFromGallery(crop: true);
                  if (file != null) setState(() => _iconFile = file);
                },
                child: Stack(
                  children: [
                    _iconFile != null
                        ? Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(image: FileImage(_iconFile!), fit: BoxFit.cover),
                            ),
                          )
                        : TenkuAvatar(
                            name: _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'C',
                            size: 80,
                          ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 26,
                        height: 26,
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
              const SizedBox(height: 32),
              TenkuTextField(
                controller: _nameCtrl,
                label: 'Community Name',
                hint: 'e.g. Anime Hub',
                prefixIcon: Icons.public_rounded,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter a community name';
                  if (v.trim().length < 3) return 'At least 3 characters';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TenkuTextField(
                controller: _descCtrl,
                label: 'Description (optional)',
                hint: 'What is this community about?',
                prefixIcon: Icons.info_outline,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Public Community', style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                        Text('Anyone can join', style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 13)),
                      ],
                    ),
                    Switch(
                      value: _isPublic,
                      onChanged: (v) => setState(() => _isPublic = v),
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              TenkuButton(
                label: 'Create Community',
                onPressed: _loading ? null : _create,
                isLoading: _loading,
                icon: Icons.add_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
