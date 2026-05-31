import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/status_service.dart';
import '../../services/storage_service.dart';

class CreateStatusScreen extends StatefulWidget {
  const CreateStatusScreen({super.key});

  @override
  State<CreateStatusScreen> createState() => _CreateStatusScreenState();
}

class _CreateStatusScreenState extends State<CreateStatusScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _textCtrl = TextEditingController();
  final _statusService = StatusService();
  final _storageService = StorageService();
  String _selectedColor = '#6C63FF';
  File? _selectedImage;
  bool _loading = false;

  final _colors = [
    '#6C63FF', '#00D4AA', '#FF6B6B', '#FFB020',
    '#00B4D8', '#9C92FF', '#FF7FAB', '#1A1A26',
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _postTextStatus() async {
    if (_textCtrl.text.trim().isEmpty) return;
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    setState(() => _loading = true);

    await _statusService.createTextStatus(
      userId: user.uid,
      userName: user.displayName,
      userAvatar: user.avatarUrl,
      text: _textCtrl.text.trim(),
      backgroundColor: _selectedColor,
    );

    setState(() => _loading = false);
    if (mounted) context.pop();
  }

  Future<void> _postImageStatus() async {
    if (_selectedImage == null) return;
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    setState(() => _loading = true);

    await _statusService.createImageStatus(
      userId: user.uid,
      userName: user.displayName,
      userAvatar: user.avatarUrl,
      imageFile: _selectedImage!,
    );

    setState(() => _loading = false);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        leading: IconButton(icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary), onPressed: () => context.pop()),
        title: Text('New Status', style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
          tabs: const [Tab(text: 'Text'), Tab(text: 'Photo')],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // Text Status
          Column(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        Color(int.parse(_selectedColor.replaceFirst('#', '0xFF'))),
                        AppColors.bgDark,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: TextField(
                        controller: _textCtrl,
                        maxLines: null,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                        decoration: InputDecoration(
                          hintText: 'What\'s on your mind?',
                          hintStyle: GoogleFonts.dmSans(color: Colors.white54, fontSize: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          fillColor: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Color picker
              SizedBox(
                height: 60,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  scrollDirection: Axis.horizontal,
                  itemCount: _colors.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final color = _colors[i];
                    final isSelected = _selectedColor == color;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: GestureDetector(
                    onTap: _loading ? null : _postTextStatus,
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: _loading
                            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            : Text('Post Status', style: GoogleFonts.dmSans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Image Status
          Column(
            children: [
              Expanded(
                child: _selectedImage != null
                    ? Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover),
                        ),
                      )
                    : GestureDetector(
                        onTap: () async {
                          final file = await _storageService.pickImageFromGallery(crop: false);
                          if (file != null) setState(() => _selectedImage = file);
                        },
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: AppColors.bgCard,
                            border: Border.all(color: AppColors.divider, width: 2),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary, size: 64),
                              const SizedBox(height: 16),
                              Text('Tap to choose a photo', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      if (_selectedImage != null)
                        GestureDetector(
                          onTap: () async {
                            final file = await _storageService.pickImageFromGallery(crop: false);
                            if (file != null) setState(() => _selectedImage = file);
                          },
                          child: Container(
                            height: 52,
                            width: 52,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: AppColors.bgElevated,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: const Icon(Icons.photo_library_outlined, color: AppColors.textSecondary),
                          ),
                        ),
                      Expanded(
                        child: GestureDetector(
                          onTap: _loading || _selectedImage == null ? null : _postImageStatus,
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: _selectedImage != null ? AppColors.primaryGradient : null,
                              color: _selectedImage == null ? AppColors.bgElevated : null,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: _loading
                                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                  : Text('Post Photo Status',
                                      style: GoogleFonts.dmSans(
                                        color: _selectedImage != null ? Colors.white : AppColors.textMuted,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      )),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
