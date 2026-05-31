import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/tenku_avatar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.bgDark,
            expandedHeight: 220,
            pinned: true,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: AppColors.textSecondary),
                onPressed: () => context.push('/edit-profile'),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary.withOpacity(0.3), AppColors.bgDark],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      TenkuAvatar(
                        imageUrl: user.avatarUrl,
                        name: user.displayName,
                        size: 82,
                        showOnlineIndicator: true,
                        isOnline: true,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.displayName,
                        style: GoogleFonts.dmSans(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${user.username}',
                        style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (user.bio.isNotEmpty) ...[
                    _InfoCard(
                      children: [
                        _InfoRow(icon: Icons.info_outline, label: 'Bio', value: user.bio),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  _InfoCard(
                    children: [
                      _InfoRow(icon: Icons.email_outlined, label: 'Email', value: user.email),
                      const Divider(color: AppColors.divider, height: 1),
                      _InfoRow(
                        icon: Icons.verified_outlined,
                        label: 'Status',
                        value: user.isEmailVerified ? 'Verified' : 'Not Verified',
                        valueColor: user.isEmailVerified ? AppColors.success : AppColors.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _InfoCard(
                    children: [
                      _InfoRow(icon: Icons.group_outlined, label: 'Communities', value: '${user.communityIds.length}'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Settings', style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.notifications_outlined,
                        label: 'Notifications',
                        onTap: () {},
                      ),
                      const Divider(color: AppColors.divider, height: 1),
                      _SettingsTile(
                        icon: Icons.privacy_tip_outlined,
                        label: 'Privacy',
                        onTap: () {},
                      ),
                      const Divider(color: AppColors.divider, height: 1),
                      _SettingsTile(
                        icon: Icons.help_outline_rounded,
                        label: 'Help & Support',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SettingsCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.logout_rounded,
                        label: 'Sign Out',
                        textColor: AppColors.error,
                        iconColor: AppColors.error,
                        onTap: () => _showSignOutDialog(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      'Tenku v1.0.0',
                      style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        title: Text('Sign Out', style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to sign out?', style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().signOut();
            },
            child: Text('Sign Out', style: GoogleFonts.dmSans(color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Text(label, style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 14)),
          const Spacer(),
          Text(value, style: GoogleFonts.dmSans(color: valueColor ?? AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;
  const _SettingsTile({required this.icon, required this.label, required this.onTap, this.textColor, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(icon, color: iconColor ?? AppColors.textSecondary, size: 22),
      title: Text(label, style: GoogleFonts.dmSans(color: textColor ?? AppColors.textPrimary, fontSize: 15)),
      trailing: textColor == null ? const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20) : null,
      onTap: onTap,
    );
  }
}
