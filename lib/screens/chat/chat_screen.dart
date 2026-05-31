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
import '../../services/chat_service.dart';
import '../../services/storage_service.dart';
import '../../models/message_model.dart';
import '../../widgets/common/tenku_avatar.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String participantName;
  final String? participantAvatar;
  final String participantId;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.participantName,
    this.participantAvatar,
    required this.participantId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _chatService = ChatService();
  final _storageService = StorageService();

  MessageModel? _replyingTo;
  MessageModel? _editingMessage;
  bool _showEmoji = false;
  Timer? _typingTimer;
  String? _currentUserId;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        _currentUserId = user.uid;
        _chatService.markAsRead(chatId: widget.chatId, userId: user.uid);
      }
    });
    _msgCtrl.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (!_isTyping && _msgCtrl.text.isNotEmpty) {
      _isTyping = true;
      if (_currentUserId != null) {
        _chatService.updateTypingStatus(chatId: widget.chatId, userId: _currentUserId!, isTyping: true);
      }
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_currentUserId != null) {
        _isTyping = false;
        _chatService.updateTypingStatus(chatId: widget.chatId, userId: _currentUserId!, isTyping: false);
      }
    });
  }

  @override
  void dispose() {
    _msgCtrl.removeListener(_onTextChanged);
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _typingTimer?.cancel();
    if (_currentUserId != null) {
      _chatService.updateTypingStatus(chatId: widget.chatId, userId: _currentUserId!, isTyping: false);
    }
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    _msgCtrl.clear();

    if (_editingMessage != null) {
      await _chatService.editMessage(chatId: widget.chatId, messageId: _editingMessage!.id, newContent: text);
      setState(() => _editingMessage = null);
      return;
    }

    await _chatService.sendMessage(
      chatId: widget.chatId,
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
    final isMe = msg.senderId == user.uid;

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
            // Reaction row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['❤️', '🔥', '😂', '😮', '😢', '👍'].map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _chatService.addReaction(chatId: widget.chatId, messageId: msg.id, emoji: emoji, userId: user.uid);
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied!'), duration: Duration(seconds: 1)),
                );
              },
            ),
            if (isMe && !msg.isDeleted) ...[
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: AppColors.textSecondary),
                title: Text('Edit', style: GoogleFonts.dmSans(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _editingMessage = msg;
                    _msgCtrl.text = msg.content;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                title: Text('Delete', style: GoogleFonts.dmSans(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _chatService.deleteMessage(chatId: widget.chatId, messageId: msg.id);
                },
              ),
            ],
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            TenkuAvatar(
              imageUrl: widget.participantAvatar,
              name: widget.participantName,
              size: 38,
              showOnlineIndicator: true,
              isOnline: false,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.participantName,
                    style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                StreamBuilder<Map<String, bool>>(
                  stream: _chatService.streamTypingStatus(widget.chatId),
                  builder: (_, snap) {
                    final typing = snap.data ?? {};
                    final otherTyping = typing.entries.any((e) => e.key != user.uid && e.value);
                    return Text(
                      otherTyping ? 'typing...' : 'online',
                      style: GoogleFonts.dmSans(
                        color: otherTyping ? AppColors.accent : AppColors.online,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.call_outlined, color: AppColors.textSecondary), onPressed: () {}),
          IconButton(icon: const Icon(Icons.videocam_outlined, color: AppColors.textSecondary), onPressed: () {}),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.streamMessages(widget.chatId),
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
                        TenkuAvatar(imageUrl: widget.participantAvatar, name: widget.participantName, size: 72),
                        const SizedBox(height: 16),
                        Text(widget.participantName,
                            style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text('Start your conversation', style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 14)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg = messages[i];
                    final isMe = msg.senderId == user.uid;
                    final showDate = i == messages.length - 1 ||
                        !_isSameDay(messages[i].createdAt, messages[i + 1].createdAt);
                    final showAvatar = !isMe && (i == 0 || messages[i - 1].senderId != msg.senderId);

                    return Column(
                      children: [
                        if (showDate) _DateDivider(date: msg.createdAt),
                        _MessageBubble(
                          message: msg,
                          isMe: isMe,
                          showAvatar: showAvatar,
                          currentUserId: user.uid,
                          onLongPress: () => _onMessageLongPress(msg),
                          onReply: () => setState(() => _replyingTo = msg),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Reply preview
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
                        Text(_replyingTo!.content, style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted, size: 18),
                    onPressed: () => setState(() => _replyingTo = null),
                  ),
                ],
              ),
            ),

          // Edit preview
          if (_editingMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.bgElevated,
              child: Row(
                children: [
                  Container(width: 3, height: 36, color: AppColors.warning),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Editing message', style: GoogleFonts.dmSans(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.w600)),
                        Text(_editingMessage!.content, style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted, size: 18),
                    onPressed: () => setState(() { _editingMessage = null; _msgCtrl.clear(); }),
                  ),
                ],
              ),
            ),

          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: AppColors.bgDark,
              border: const Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
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
                          hintText: 'Message...',
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
                          child: Icon(
                            hasText ? Icons.send_rounded : Icons.mic_rounded,
                            color: hasText ? Colors.white : AppColors.textMuted,
                            size: 20,
                          ),
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
                  searchViewConfig: SearchViewConfig(backgroundColor: AppColors.bgElevated, buttonColor: AppColors.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DateDivider extends StatelessWidget {
  final DateTime date;
  const _DateDivider({required this.date});

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

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool showAvatar;
  final String currentUserId;
  final VoidCallback onLongPress;
  final VoidCallback onReply;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showAvatar,
    required this.currentUserId,
    required this.onLongPress,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(message.createdAt);

    return Padding(
      padding: EdgeInsets.only(
        top: 2,
        bottom: 2,
        left: isMe ? 48 : 0,
        right: isMe ? 0 : 48,
      ),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar)
            Padding(
              padding: const EdgeInsets.only(right: 6, bottom: 2),
              child: TenkuAvatar(name: message.senderName, size: 28),
            )
          else if (!isMe)
            const SizedBox(width: 34),

          GestureDetector(
            onLongPress: onLongPress,
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe && showAvatar)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2, left: 4),
                    child: Text(message.senderName,
                        style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),

                // Reply preview
                if (message.replyToId != null && !message.isDeleted)
                  Container(
                    margin: const EdgeInsets.only(bottom: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.primaryDark.withOpacity(0.5) : AppColors.bgDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border(left: BorderSide(color: isMe ? AppColors.accentGlow : AppColors.primary, width: 2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(message.replyToSenderName ?? '', style: GoogleFonts.dmSans(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                        Text(message.replyToContent ?? '', style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),

                // Bubble
                Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.68),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.myBubble : AppColors.theirBubble,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    boxShadow: isMe
                        ? [BoxShadow(color: AppColors.primary.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2))]
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        message.isDeleted ? 'This message was deleted' : message.content,
                        style: GoogleFonts.dmSans(
                          color: message.isDeleted ? AppColors.textMuted : AppColors.textPrimary,
                          fontSize: 14.5,
                          fontStyle: message.isDeleted ? FontStyle.italic : FontStyle.normal,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (message.editedAt != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text('edited', style: GoogleFonts.dmSans(color: AppColors.textMuted.withOpacity(0.7), fontSize: 10)),
                            ),
                          Text(timeStr, style: GoogleFonts.dmSans(color: AppColors.textMuted.withOpacity(0.8), fontSize: 10)),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            _ReadReceipt(status: message.status),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Reactions
                if (message.reactions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Wrap(
                      spacing: 4,
                      children: message.reactions.map((r) {
                        final count = r.userIds.length;
                        final iReacted = r.userIds.contains(currentUserId);
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: iReacted ? AppColors.primary.withOpacity(0.2) : AppColors.bgElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: iReacted ? AppColors.primary.withOpacity(0.5) : AppColors.divider),
                          ),
                          child: Text('${r.emoji} $count', style: const TextStyle(fontSize: 12)),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadReceipt extends StatelessWidget {
  final MessageStatus status;
  const _ReadReceipt({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MessageStatus.sending:
        return const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.textMuted));
      case MessageStatus.sent:
        return const Icon(Icons.check_rounded, size: 14, color: AppColors.textMuted);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all_rounded, size: 14, color: AppColors.textMuted);
      case MessageStatus.read:
        return const Icon(Icons.done_all_rounded, size: 14, color: AppColors.accent);
      case MessageStatus.failed:
        return const Icon(Icons.error_outline_rounded, size: 14, color: AppColors.error);
    }
  }
}
