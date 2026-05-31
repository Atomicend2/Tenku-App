import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/community_service.dart';
import '../../models/community_model.dart';
import '../../widgets/common/tenku_avatar.dart';

class CommunityDetailScreen extends StatefulWidget {
  final String communityId;
  const CommunityDetailScreen({super.key, required this.communityId});

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  final _communityService = CommunityService();
  String? _selectedChannelId;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) return const SizedBox();

    return StreamBuilder<CommunityModel?>(
      stream: Stream.fromFuture(_communityService.getCommunity(widget.communityId)),
      builder: (context, communitySnap) {
        final community = communitySnap.data;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.bgDark,
          appBar: AppBar(
            backgroundColor: AppColors.bgDark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
              onPressed: () => context.pop(),
            ),
            title: GestureDetector(
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
              child: Row(
                children: [
                  if (community != null)
                    TenkuAvatar(imageUrl: community.iconUrl, name: community.name, size: 34),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          community?.name ?? 'Loading...',
                          style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (community != null)
                          Text('${community.memberCount} members',
                              style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(icon: const Icon(Icons.menu_rounded, color: AppColors.textSecondary), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
              if (community?.isMember(user.uid) == false)
                TextButton(
                  onPressed: () => _communityService.joinCommunity(communityId: widget.communityId, userId: user.uid),
                  child: Text('Join', style: GoogleFonts.dmSans(color: AppColors.primary, fontWeight: FontWeight.w700)),
                ),
              const SizedBox(width: 8),
            ],
          ),
          drawer: _ChannelDrawer(
            communityId: widget.communityId,
            community: community,
            selectedChannelId: _selectedChannelId,
            currentUserId: user.uid,
            onChannelTap: (channelId, channelName) {
              _scaffoldKey.currentState?.closeDrawer();
              context.push('/community/${widget.communityId}/channel/$channelId',
                  extra: {'name': channelName});
            },
            onLeaveCommunity: () {
              _communityService.leaveCommunity(communityId: widget.communityId, userId: user.uid);
              context.pop();
            },
          ),
          body: _selectedChannelId == null
              ? _CommunityLanding(community: community, onChannelTap: (id, name) {
                  context.push('/community/${widget.communityId}/channel/$id', extra: {'name': name});
                })
              : const SizedBox(),
        );
      },
    );
  }
}

class _ChannelDrawer extends StatelessWidget {
  final String communityId;
  final CommunityModel? community;
  final String? selectedChannelId;
  final String currentUserId;
  final Function(String, String) onChannelTap;
  final VoidCallback onLeaveCommunity;

  const _ChannelDrawer({
    required this.communityId,
    required this.community,
    required this.selectedChannelId,
    required this.currentUserId,
    required this.onChannelTap,
    required this.onLeaveCommunity,
  });

  @override
  Widget build(BuildContext context) {
    final communityService = CommunityService();

    return Drawer(
      backgroundColor: AppColors.bgCard,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Community Header
            if (community != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.divider)),
                ),
                child: Row(
                  children: [
                    TenkuAvatar(imageUrl: community!.iconUrl, name: community!.name, size: 42),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(community!.name,
                              style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis),
                          Text('${community!.memberCount} members',
                              style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Channels list
            Expanded(
              child: StreamBuilder<List<ChannelModel>>(
                stream: communityService.streamChannels(communityId),
                builder: (ctx, snap) {
                  final channels = snap.data ?? [];
                  final textChannels = channels.where((c) => c.type != ChannelType.voice).toList();
                  final voiceChannels = channels.where((c) => c.type == ChannelType.voice).toList();

                  return ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      if (textChannels.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                          child: Text('TEXT CHANNELS',
                              style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                        ),
                        ...textChannels.map((ch) => _ChannelTile(
                          channel: ch,
                          isSelected: selectedChannelId == ch.id,
                          onTap: () => onChannelTap(ch.id, ch.name),
                        )),
                      ],
                      if (voiceChannels.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                          child: Text('VOICE CHANNELS',
                              style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                        ),
                        ...voiceChannels.map((ch) => _ChannelTile(
                          channel: ch,
                          isSelected: selectedChannelId == ch.id,
                          onTap: () => onChannelTap(ch.id, ch.name),
                        )),
                      ],

                      // Add channel
                      if (community?.isAdmin(currentUserId) == true)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: ListTile(
                            leading: const Icon(Icons.add_rounded, color: AppColors.primary, size: 20),
                            title: Text('Add Channel', style: GoogleFonts.dmSans(color: AppColors.primary, fontSize: 14)),
                            dense: true,
                            onTap: () => _showCreateChannelDialog(context, communityId, communityService),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),

            // Leave community
            if (community?.isOwner(currentUserId) == false)
              Container(
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
                child: ListTile(
                  leading: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                  title: Text('Leave Community', style: GoogleFonts.dmSans(color: AppColors.error, fontSize: 14)),
                  onTap: onLeaveCommunity,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showCreateChannelDialog(BuildContext context, String communityId, CommunityService service) {
    final nameCtrl = TextEditingController();
    ChannelType selectedType = ChannelType.text;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppColors.bgElevated,
          title: Text('Create Channel', style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: GoogleFonts.dmSans(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'channel-name',
                  hintStyle: GoogleFonts.dmSans(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.bgInput,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: ChannelType.values.map((t) {
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setS(() => selectedType = t),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selectedType == t ? AppColors.primary : AppColors.bgCard,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(t.name, style: GoogleFonts.dmSans(
                            color: selectedType == t ? Colors.white : AppColors.textMuted,
                            fontSize: 13, fontWeight: FontWeight.w600,
                          )),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                final name = nameCtrl.text.trim().toLowerCase().replaceAll(' ', '-');
                if (name.isNotEmpty) {
                  service.createChannel(communityId: communityId, name: name, type: selectedType);
                  Navigator.pop(context);
                }
              },
              child: Text('Create', style: GoogleFonts.dmSans(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChannelTile extends StatelessWidget {
  final ChannelModel channel;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChannelTile({required this.channel, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(channel.prefix, style: TextStyle(color: isSelected ? AppColors.primary : AppColors.textMuted, fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                channel.name,
                style: GoogleFonts.dmSans(
                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityLanding extends StatelessWidget {
  final CommunityModel? community;
  final Function(String, String) onChannelTap;

  const _CommunityLanding({required this.community, required this.onChannelTap});

  @override
  Widget build(BuildContext context) {
    if (community == null) return const Center(child: CircularProgressIndicator(color: AppColors.primary));

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TenkuAvatar(imageUrl: community!.iconUrl, name: community!.name, size: 80),
            const SizedBox(height: 20),
            Text(community!.name,
                style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center),
            if (community!.description != null) ...[
              const SizedBox(height: 8),
              Text(community!.description!,
                  style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 15),
                  textAlign: TextAlign.center),
            ],
            const SizedBox(height: 16),
            Text('${community!.memberCount} members',
                style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 14)),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  const Icon(Icons.menu_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Text('Open the drawer to select a channel', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
