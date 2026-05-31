import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../models/message_model.dart';
import '../../widgets/common/tenku_avatar.dart';

class ChatsListScreen extends StatelessWidget {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) return const SizedBox();
    final chatService = ChatService();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        titleSpacing: 20,
        title: Text('Chats', style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(icon: const Icon(Icons.search_rounded), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => _showNewChatSheet(context, user.uid),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<ChatModel>>(
        stream: chatService.streamChats(user.uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2));
          }
          final chats = snap.data ?? [];
          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.textMuted, size: 64),
                  const SizedBox(height: 16),
                  Text('No conversations yet', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('Start chatting with someone!', style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 14)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: chats.length,
            separatorBuilder: (_, __) => const Divider(color: AppColors.divider, height: 1, indent: 80),
            itemBuilder: (_, i) {
              final chat = chats[i];
              final name = chat.getDisplayName(user.uid);
              final avatar = chat.getDisplayAvatar(user.uid);
              final otherId = chat.getOtherParticipantId(user.uid);
              final unread = chat.unreadCounts[user.uid] ?? 0;
              final lastMsg = chat.lastMessage;
              final isTyping = chat.isTyping.entries.any((e) => e.key != user.uid && e.value);

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: TenkuAvatar(imageUrl: avatar, name: name, size: 52, showOnlineIndicator: true, isOnline: false),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name, style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                    Text(
                      chat.lastMessageAt != null ? timeago.format(chat.lastMessageAt!, locale: 'en_short') : '',
                      style: GoogleFonts.dmSans(color: unread > 0 ? AppColors.primary : AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
                subtitle: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: isTyping
                          ? Text('typing...', style: GoogleFonts.dmSans(color: AppColors.accent, fontSize: 13, fontStyle: FontStyle.italic))
                          : Text(
                              lastMsg?.isDeleted == true ? 'Message deleted' : (lastMsg?.content ?? ''),
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
                onTap: () => context.push('/chat/${chat.id}',
                    extra: {'name': name, 'avatar': avatar, 'participantId': otherId}),
              );
            },
          );
        },
      ),
    );
  }

  void _showNewChatSheet(BuildContext context, String currentUserId) {
    final searchCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgElevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (ctx, scrollCtrl) => Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textMuted, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('New Message', style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: searchCtrl,
                style: GoogleFonts.dmSans(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  hintStyle: GoogleFonts.dmSans(color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                  filled: true,
                  fillColor: AppColors.bgInput,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Center(
                child: Text('Search for users to chat', style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
