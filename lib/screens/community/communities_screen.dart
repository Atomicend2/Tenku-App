import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/community_service.dart';
import '../../models/community_model.dart';
import '../../widgets/common/tenku_avatar.dart';

class CommunitiesScreen extends StatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  State<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends State<CommunitiesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) return const SizedBox();
    final communityService = CommunityService();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        titleSpacing: 20,
        title: Text('Communities', style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(icon: const Icon(Icons.search_rounded), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push('/create-community'),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: const [Tab(text: 'My Communities'), Tab(text: 'Discover')],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // My Communities
          StreamBuilder<List<CommunityModel>>(
            stream: communityService.streamUserCommunities(user.uid),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2));
              }
              final communities = snap.data ?? [];
              if (communities.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.public_outlined, color: AppColors.textMuted, size: 64),
                      const SizedBox(height: 16),
                      Text('No communities yet', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text('Create or join a community!', style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 14)),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () => context.push('/create-community'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('Create Community', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: communities.length,
                separatorBuilder: (_, __) => const Divider(color: AppColors.divider, height: 1, indent: 76),
                itemBuilder: (_, i) => _CommunityListItem(
                  community: communities[i],
                  onTap: () => context.push('/community/${communities[i].id}'),
                ),
              );
            },
          ),

          // Discover
          StreamBuilder<List<CommunityModel>>(
            stream: communityService.streamPublicCommunities(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2));
              }
              final communities = (snap.data ?? []).where((c) => !c.isMember(user.uid)).toList();
              if (communities.isEmpty) {
                return Center(child: Text('No public communities yet', style: GoogleFonts.dmSans(color: AppColors.textMuted)));
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: communities.length,
                separatorBuilder: (_, __) => const Divider(color: AppColors.divider, height: 1, indent: 76),
                itemBuilder: (_, i) => _CommunityListItem(
                  community: communities[i],
                  showJoin: true,
                  onTap: () => context.push('/community/${communities[i].id}'),
                  onJoin: () => communityService.joinCommunity(communityId: communities[i].id, userId: user.uid),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CommunityListItem extends StatelessWidget {
  final CommunityModel community;
  final VoidCallback onTap;
  final bool showJoin;
  final VoidCallback? onJoin;

  const _CommunityListItem({
    required this.community,
    required this.onTap,
    this.showJoin = false,
    this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: TenkuAvatar(imageUrl: community.iconUrl, name: community.name, size: 52),
      title: Text(community.name, style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
      subtitle: Text(
        community.description ?? '${community.memberCount} members',
        style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 13),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: showJoin
          ? GestureDetector(
              onTap: onJoin,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Join', style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            )
          : const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
      onTap: onTap,
    );
  }
}
