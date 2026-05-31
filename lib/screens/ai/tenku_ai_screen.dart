import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/ai_service.dart';

class TenkuAIScreen extends StatefulWidget {
  final String? channelId;
  final String? chatId;
  final String? initialCommand;

  const TenkuAIScreen({super.key, this.channelId, this.chatId, this.initialCommand});

  @override
  State<TenkuAIScreen> createState() => _TenkuAIScreenState();
}

class _TenkuAIScreenState extends State<TenkuAIScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _aiService = TenkuAIService();
  final List<_ChatMessage> _messages = [];
  bool _isThinking = false;
  List<AIMessage> _history = [];

  static const _suggestions = [
    '📝 Summarize this channel',
    '📋 Create meeting notes',
    '💡 Explain the last topic',
    '✍️ Rewrite my last message',
    '🌍 Translate to English',
  ];

  @override
  void initState() {
    super.initState();
    _addWelcome();
    if (widget.initialCommand != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendMessage(widget.initialCommand!);
      });
    }
  }

  void _addWelcome() {
    _messages.add(_ChatMessage(
      role: 'assistant',
      content: "👋 Hey! I'm **TenkuAI**, your smart assistant.\n\nI can:\n• 📝 Summarize channel conversations\n• 📋 Create meeting notes\n• 💡 Explain topics\n• 🌍 Translate messages\n• ✍️ Rewrite text\n• 💬 Answer any question\n\nJust type or tap a suggestion below!",
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isThinking) return;
    _msgCtrl.clear();

    final userMsg = _ChatMessage(role: 'user', content: text, timestamp: DateTime.now());
    setState(() {
      _messages.add(userMsg);
      _isThinking = true;
    });
    _scrollToBottom();

    final command = TenkuAIService.parseCommand(text) ?? TenkuAICommand.freestyle;

    final response = await _aiService.respond(
      userMessage: text,
      command: command,
      channelId: widget.channelId,
      chatId: widget.chatId,
      conversationHistory: _history,
    );

    _history = [
      ..._history,
      AIMessage(role: 'user', content: text),
      AIMessage(role: 'assistant', content: response),
    ];
    // Keep history bounded
    if (_history.length > 20) _history = _history.sublist(_history.length - 20);

    setState(() {
      _messages.add(_ChatMessage(role: 'assistant', content: response, timestamp: DateTime.now()));
      _isThinking = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            // AI Avatar
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF00D4AA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(child: Text('AI', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800))),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TenkuAI', style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.success)),
                    const SizedBox(width: 4),
                    Text('Always available', style: GoogleFonts.dmSans(color: AppColors.success, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () {
              setState(() {
                _messages.clear();
                _history = [];
                _addWelcome();
              });
            },
            tooltip: 'Clear conversation',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length + (_isThinking ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _messages.length && _isThinking) {
                  return _ThinkingBubble();
                }
                return _AIMessageBubble(message: _messages[i]);
              },
            ),
          ),

          // Suggestions (show only at start)
          if (_messages.length <= 1)
            SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _sendMessage(_suggestions[i]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Text(
                      _suggestions[i],
                      style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ),

          // Input
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
                          hintText: 'Ask TenkuAI anything...',
                          hintStyle: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 15),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onSubmitted: (v) => _sendMessage(v),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _isThinking ? null : () => _sendMessage(_msgCtrl.text),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _isThinking ? null : const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF00D4AA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        color: _isThinking ? AppColors.bgElevated : null,
                      ),
                      child: _isThinking
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String role;
  final String content;
  final DateTime timestamp;
  const _ChatMessage({required this.role, required this.content, required this.timestamp});
}

class _AIMessageBubble extends StatelessWidget {
  final _ChatMessage message;
  const _AIMessageBubble({required this.message});

  bool get isAI => message.role == 'assistant';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 4, bottom: 4,
        left: isAI ? 0 : 48,
        right: isAI ? 48 : 0,
      ),
      child: Row(
        mainAxisAlignment: isAI ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isAI) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF00D4AA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(child: Text('AI', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800))),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isAI ? AppColors.bgElevated : AppColors.myBubble,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isAI ? 4 : 18),
                  bottomRight: Radius.circular(isAI ? 18 : 4),
                ),
                border: isAI ? Border.all(color: AppColors.divider) : null,
                boxShadow: isAI ? null : [
                  BoxShadow(color: AppColors.primary.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildContent(message.content),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(message.timestamp),
                    style: GoogleFonts.dmSans(color: AppColors.textMuted.withOpacity(0.7), fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(String text) {
    // Simple markdown-like rendering
    final lines = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        if (line.startsWith('**') && line.endsWith('**')) {
          return Text(
            line.replaceAll('**', ''),
            style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 14.5, fontWeight: FontWeight.w700),
          );
        }
        if (line.startsWith('• ') || line.startsWith('- ')) {
          return Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(color: AppColors.primary, fontSize: 14)),
                Expanded(child: Text(line.substring(2), style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 14, height: 1.5))),
              ],
            ),
          );
        }
        if (line.startsWith('#')) {
          final level = line.indexOf(' ');
          return Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 2),
            child: Text(
              line.substring(level + 1),
              style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
            ),
          );
        }
        return Text(
          _parseInline(line),
          style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 14.5, height: 1.5),
        );
      }).toList(),
    );
  }

  String _parseInline(String text) {
    return text.replaceAll('**', '').replaceAll('__', '').replaceAll('`', '');
  }
}

class _ThinkingBubble extends StatefulWidget {
  @override
  State<_ThinkingBubble> createState() => _ThinkingBubbleState();
}

class _ThinkingBubbleState extends State<_ThinkingBubble> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _anim = Tween<double>(begin: 0, end: 1).animate(_ctrl);
    _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4, right: 48),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            margin: const EdgeInsets.only(right: 8, bottom: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF00D4AA)]),
            ),
            child: const Center(child: Text('AI', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800))),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.bgElevated,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18), topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4), bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _anim,
                  builder: (_, __) => Container(
                    width: 7, height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(
                        ((_anim.value + i * 0.33) % 1.0).clamp(0.3, 1.0),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
