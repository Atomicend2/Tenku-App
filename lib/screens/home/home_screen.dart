import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../services/community_service.dart';
import '../../services/status_service.dart';
import '../../models/message_model.dart';
import '../../models/community_model.dart';
import '../../models/status_model.dart';
import '../../widgets/common/tenku_avatar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    if (user == null) return const SizedBox();

    final chatService = ChatService();
    final communityService = CommunityService();
    final statusService = StatusService();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.bgDark,
            floating: true,
            pinned: false,
            elevation: 0,
            titleSpacing: 20,
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: AppColors.primaryGradient,
                  ),
                  child: const Center(
                    child: Text('T', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 10),
                Text('Tenku', style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hey, ${user.displayName.split(' ').first} 👋',
                    style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 24),

                  // Status row
                  _SectionHeader(title: 'Status', onSeeAll: () => context.go('/status')),
                  const SizedBox(height: 12),
                  StreamBuilder<List<StatusModel>>(
                    stream: statusService.streamStatuses(user.uid),
                    builder: (context, snap) {
                      final statuses = snap.data ?? [];
                      final groups = statusService.groupStatusesByUser(statuses, user.uid);
                      return SizedBox(
                        height: 88,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: groups.length + 1,
                          separatorBuilder: (_, __) => const SizedBox(width: 14),
                          itemBuilder: (_, i) {
                            if (i == 0) {
                              return _AddStatusButton(onTap: () => context.push('/create-status'));
                            }
                            final group = groups[i - 1];
                            return _StatusCircle(group: group, currentUserId: user.uid);
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),

                  // Recent Chats
                  _SectionHeader(title: 'Recent Chats', onSeeAll: () => context.go('/chats')),
                  const SizedBox(height: 12),
                  StreamBuilder<List<ChatModel>>(
                    stream: chatService.streamChats(user.uid),
                    builder: (context, snap) {
                      final chats = (snap.data ?? []).take(4).toList();
                      if (chats.isEmpty) {
                        return _EmptyCard(
                          icon: Icons.chat_bubble_outline_rounded,
                          message: 'No chats yet. Start a conversation!',
                        );
                      }
                      return Column(
                        children: chats.map((chat) {
                          final name = chat.getDisplayName(user.uid);
                          final avatar = chat.getDisplayAvatar(user.uid);
                          final otherId = chat.getOtherParticipantId(user.uid);
                          final unread = chat.unreadCounts[user.uid] ?? 0;
                          final lastMsg = chat.lastMessage;
                          return _ChatListItem(
                            name: name,
                            avatarUrl: avatar,
                            lastMessage: lastMsg?.isDeleted == true
                                ? 'Message deleted'
                                : lastMsg?.content ?? '',
                            time: chat.lastMessageAt != null
                                ? timeago.format(chat.lastMessageAt!, locale: 'en_short')
                                : '',
                            unread: unread,
                            isOnline: false,
                            onTap: () => context.push('/chat/${chat.id}',
                                extra: {'name': name, 'avatar': avatar, 'participantId': otherId}),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 28),

                  // Communities
                  _SectionHeader(title: 'Communities', onSeeAll: () => context.go('/communities')),
                  const SizedBox(height: 12),
                  StreamBuilder<List<CommunityModel>>(
                    stream: communityService.streamUserCommunities(user.uid),
                    builder: (context, snap) {
                      final communities = (snap.data ?? []).take(5).toList();
                      if (communities.isEmpty) {
                        return _EmptyCard(
                          icon: Icons.public_outlined,
                          message: 'Join or create a community!',
                        );
                      }
                      return SizedBox(
                        height: 90,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: communities.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (_, i) => _CommunityChip(
                            community: communities[i],
                            onTap: () => context.push('/community/${communities[i].id}'),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
            child: Text('See all', style: GoogleFonts.dmSans(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}

class _AddStatusButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddStatusButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.divider, width: 2),
              color: AppColors.bgCard,
            ),
            child: const Icon(Icons.add, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 6),
          Text('Add', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _StatusCircle extends StatelessWidget {
  final UserStatusGroup group;
  final String currentUserId;
  const _StatusCircle({required this.group, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: group.isViewed
                  ? null
                  : const LinearGradient(colors: [AppColors.primary, AppColors.accent]),
              border: group.isViewed
                  ? Border.all(color: AppColors.textMuted, width: 2)
                  : null,
            ),
            padding: const EdgeInsets.all(2.5),
            child: TenkuAvatar(
              imageUrl: group.userAvatar,
              name: group.userName,
              size: 54,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 62,
            child: Text(
              group.userId == currentUserId ? 'My Status' : group.userName.split(' ').first,
              style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 11),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatListItem extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final String lastMessage;
  final String time;
  final int unread;
  final bool isOnline;
  final VoidCallback onTap;

  const _ChatListItem({
    required this.name,
    this.avatarUrl,
    required this.lastMessage,
    required this.time,
    required this.unread,
    required this.isOnline,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.transparent,
        ),
        child: Row(
          children: [
            TenkuAvatar(
              imageUrl: avatarUrl,
              name: name,
              size: 48,
              showOnlineIndicator: true,
              isOnline: isOnline,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name, style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                      Text(time, style: GoogleFonts.dmSans(color: unread > 0 ? AppColors.primary : AppColors.textMuted, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage,
                          style: GoogleFonts.dmSans(
                            color: unread > 0 ? AppColors.textSecondary : AppColors.textMuted,
                            fontSize: 13,
                            fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unread > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('$unread', style: GoogleFonts.dmSans(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityChip extends StatelessWidget {
  final CommunityModel community;
  final VoidCallback onTap;
  const _CommunityChip({required this.community, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          TenkuAvatar(imageUrl: community.iconUrl, name: community.name, size: 58),
          const SizedBox(height: 6),
          SizedBox(
            width: 62,
            child: Text(
              community.name,
              style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 11),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 24),
          const SizedBox(width: 12),
          Text(message, style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 14)),
        ],
      ),
    );
  }
}
