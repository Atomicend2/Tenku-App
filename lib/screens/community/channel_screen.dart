import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/community_service.dart';
import '../../models/message_model.dart';
import '../../widgets/common/tenku_avatar.dart';

class ChannelScreen extends StatefulWidget {
  final String channelId;
  final String communityId;
  final String channelName;

  const ChannelScreen({
    super.key,
    required this.channelId,
    required this.communityId,
    required this.channelName,
  });

  @override
  State<ChannelScreen> createState() => _ChannelScreenState();
}

class _ChannelScreenState extends State<ChannelScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _communityService = CommunityService();
  MessageModel? _replyingTo;
  bool _showEmoji = false;

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    _msgCtrl.clear();

    await _communityService.sendChannelMessage(
      channelId: widget.channelId,
      communityId: widget.communityId,
      senderId: user.uid,
      senderName: user.displayName,
      senderAvatar: user.avatarUrl,
      content: text,
      replyToId: _replyingTo?.id,
      replyToContent: _replyingTo?.content,
      replyToSenderName: _replyingTo?.senderName,
    );
    setState(() => _replyingTo = null);
  }

  void _onMessageLongPress(MessageModel msg) {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textMuted, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['❤️', '🔥', '😂', '😮', '😢', '👍'].map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _communityService.addReaction(channelId: widget.channelId, messageId: msg.id, emoji: emoji, userId: user.uid);
                    },
                    child: Text(emoji, style: const TextStyle(fontSize: 28)),
                  );
                }).toList(),
              ),
            ),
            const Divider(color: AppColors.divider),
            ListTile(
              leading: const Icon(Icons.reply_rounded, color: AppColors.primary),
              title: Text('Reply', style: GoogleFonts.dmSans(color: AppColors.textPrimary)),
              onTap: () { Navigator.pop(context); setState(() => _replyingTo = msg); },
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded, color: AppColors.textSecondary),
              title: Text('Copy', style: GoogleFonts.dmSans(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: msg.content));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!'), duration: Duration(seconds: 1)));
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
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
        titleSpacing: 0,
        title: Row(
          children: [
            Text('#', style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(width: 4),
            Text(widget.channelName, style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search_rounded, color: AppColors.textSecondary), onPressed: () {}),
          IconButton(icon: const Icon(Icons.people_outline_rounded, color: AppColors.textSecondary), onPressed: () {}),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _communityService.streamChannelMessages(widget.channelId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2));
                }
                final messages = snap.data ?? [];
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('#', style: GoogleFonts.dmSans(color: AppColors.primary, fontSize: 64, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Text('Welcome to #${widget.channelName}!',
                            style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text('Start the conversation!', style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 14)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollCtrl,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg = messages[i];
                    final isMe = msg.senderId == user.uid;
                    final showDate = i == messages.length - 1 ||
                        !_isSameDay(messages[i].createdAt, messages[i + 1].createdAt);
                    final showHeader = i == messages.length - 1 ||
                        messages[i + 1].senderId != msg.senderId ||
                        msg.createdAt.difference(messages[i + 1].createdAt).inMinutes > 5;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showDate) _ChannelDateDivider(date: msg.createdAt),
                        _ChannelMessage(
                          message: msg,
                          isMe: isMe,
                          showHeader: showHeader,
                          currentUserId: user.uid,
                          onLongPress: () => _onMessageLongPress(msg),
                          channelId: widget.channelId,
                          communityService: _communityService,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          if (_replyingTo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.bgElevated,
              child: Row(
                children: [
                  Container(width: 3, height: 36, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Replying to ${_replyingTo!.senderName}',
                            style: GoogleFonts.dmSans(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                        Text(_replyingTo!.content, style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close, color: AppColors.textMuted, size: 18), onPressed: () => setState(() => _replyingTo = null)),
                ],
              ),
            ),

          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: const BoxDecoration(
              color: AppColors.bgDark,
              border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(_showEmoji ? Icons.keyboard_rounded : Icons.emoji_emotions_outlined, color: AppColors.textMuted),
                    onPressed: () => setState(() => _showEmoji = !_showEmoji),
                  ),
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: AppColors.bgInput,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: TextField(
                        controller: _msgCtrl,
                        maxLines: null,
                        style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Message #${widget.channelName}',
                          hintStyle: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 15),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ValueListenableBuilder(
                    valueListenable: _msgCtrl,
                    builder: (_, v, __) {
                      final hasText = v.text.trim().isNotEmpty;
                      return GestureDetector(
                        onTap: hasText ? _sendMessage : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: hasText ? AppColors.primaryGradient : null,
                            color: hasText ? null : AppColors.bgElevated,
                          ),
                          child: Icon(Icons.send_rounded, color: hasText ? Colors.white : AppColors.textMuted, size: 20),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          if (_showEmoji)
            SizedBox(
              height: 280,
              child: EmojiPicker(
                onEmojiSelected: (_, emoji) {
                  _msgCtrl.text += emoji.emoji;
                  _msgCtrl.selection = TextSelection.fromPosition(TextPosition(offset: _msgCtrl.text.length));
                },
                config: const Config(
                  bgColor: AppColors.bgElevated,
                  categoryViewConfig: CategoryViewConfig(backgroundColor: AppColors.bgElevated),
                  emojiViewConfig: EmojiViewConfig(backgroundColor: AppColors.bgElevated),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

class _ChannelDateDivider extends StatelessWidget {
  final DateTime date;
  const _ChannelDateDivider({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String label;
    if (_isSameDay(date, now)) label = 'Today';
    else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) label = 'Yesterday';
    else label = DateFormat('MMMM d, y').format(date);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.divider)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label, style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12)),
          ),
          const Expanded(child: Divider(color: AppColors.divider)),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

class _ChannelMessage extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool showHeader;
  final String currentUserId;
  final VoidCallback onLongPress;
  final String channelId;
  final CommunityService communityService;

  const _ChannelMessage({
    required this.message,
    required this.isMe,
    required this.showHeader,
    required this.currentUserId,
    required this.onLongPress,
    required this.channelId,
    required this.communityService,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Padding(
        padding: EdgeInsets.only(top: showHeader ? 12 : 2, bottom: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader)
              TenkuAvatar(imageUrl: message.senderAvatar, name: message.senderName, size: 36)
            else
              const SizedBox(width: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showHeader)
                    Row(
                      children: [
                        Text(message.senderName,
                            style: GoogleFonts.dmSans(
                              color: isMe ? AppColors.primaryLight : AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            )),
                        const SizedBox(width: 8),
                        Text(DateFormat('HH:mm').format(message.createdAt),
                            style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 11)),
                      ],
                    ),

                  if (message.replyToId != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(6),
                        border: const Border(left: BorderSide(color: AppColors.primary, width: 2)),
                      ),
                      child: Text('${message.replyToSenderName}: ${message.replyToContent}',
                          style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12), overflow: TextOverflow.ellipsis),
                    ),

                  Text(
                    message.isDeleted ? 'Message deleted' : message.content,
                    style: GoogleFonts.dmSans(
                      color: message.isDeleted ? AppColors.textMuted : AppColors.textPrimary,
                      fontSize: 14.5,
                      height: 1.4,
                      fontStyle: message.isDeleted ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),

                  if (message.reactions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 4,
                        children: message.reactions.map((r) {
                          final count = r.userIds.length;
                          final iReacted = r.userIds.contains(currentUserId);
                          return GestureDetector(
                            onTap: () => communityService.addReaction(
                              channelId: channelId, messageId: message.id, emoji: r.emoji, userId: currentUserId),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: iReacted ? AppColors.primary.withOpacity(0.2) : AppColors.bgElevated,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: iReacted ? AppColors.primary.withOpacity(0.5) : AppColors.divider),
                              ),
                              child: Text('${r.emoji} $count', style: const TextStyle(fontSize: 12)),
                            ),
                          );
                        }).toList(),
                      ),
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
