import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

// ============================================================
// TENKU AI SERVICE
// Powered by Anthropic Claude API
//
// Setup:
//   1. Get API key at https://console.anthropic.com
//   2. Store in Firebase Remote Config key "claude_api_key"
//      OR set TENKU_AI_KEY directly below (dev only)
//   3. In production, call Claude via a Firebase Cloud Function
//      so your API key is never exposed in the app.
// ============================================================

enum TenkuAICommand {
  summarize,
  meetingNotes,
  translate,
  explain,
  rewrite,
  freestyle,
}

class AIMessage {
  final String role; // 'user' | 'assistant'
  final String content;
  const AIMessage({required this.role, required this.content});

  Map<String, dynamic> toMap() => {'role': role, 'content': content};
}

class TenkuAIService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ⚠️ In production: put your key in Firebase Remote Config
  // or call Claude via a Firebase Cloud Function.
  // NEVER ship a real API key in app code.
  static const String _apiBase = 'https://api.anthropic.com/v1/messages';
  static const String _model = 'claude-3-5-haiku-20241022'; // fast + affordable
  static const String _claudeApiKey = 'YOUR_CLAUDE_API_KEY'; // Replace this

  // ─── Parse @TenkuAI commands ─────────────────────────────
  static TenkuAICommand? parseCommand(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('summarize') || lower.contains('summary')) return TenkuAICommand.summarize;
    if (lower.contains('meeting notes') || lower.contains('notes')) return TenkuAICommand.meetingNotes;
    if (lower.contains('translate')) return TenkuAICommand.translate;
    if (lower.contains('explain')) return TenkuAICommand.explain;
    if (lower.contains('rewrite') || lower.contains('rephrase')) return TenkuAICommand.rewrite;
    return TenkuAICommand.freestyle;
  }

  // ─── Fetch recent channel messages for context ───────────
  Future<List<String>> _getChannelContext(String channelId, {int limit = 30}) async {
    final snap = await _db
        .collection('channels')
        .doc(channelId)
        .collection('messages')
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    final messages = snap.docs.map((d) => MessageModel.fromFirestore(d)).toList().reversed.toList();
    return messages.map((m) => '${m.senderName}: ${m.content}').toList();
  }

  // ─── Fetch recent DM messages for context ────────────────
  Future<List<String>> _getChatContext(String chatId, {int limit = 30}) async {
    final snap = await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    final messages = snap.docs.map((d) => MessageModel.fromFirestore(d)).toList().reversed.toList();
    return messages.map((m) => '${m.senderName}: ${m.content}').toList();
  }

  // ─── Build system prompt ──────────────────────────────────
  String _buildSystemPrompt(TenkuAICommand command) {
    const base = '''You are TenkuAI, a helpful assistant built into the Tenku chat app.
You are concise, friendly, and helpful. You format responses cleanly for a chat interface.
Keep responses under 500 words unless asked for more. Use bullet points for lists.''';

    switch (command) {
      case TenkuAICommand.summarize:
        return '$base\nYour task: Summarize the provided chat messages into a concise bullet-point summary. Highlight key topics, decisions, and action items.';
      case TenkuAICommand.meetingNotes:
        return '$base\nYour task: Turn the chat messages into structured meeting notes with sections: Summary, Key Decisions, Action Items, and Next Steps.';
      case TenkuAICommand.translate:
        return '$base\nYour task: Translate the provided text to English (or detect the target language from context). Show original then translation.';
      case TenkuAICommand.explain:
        return '$base\nYour task: Explain the topic or concept mentioned clearly and concisely for a general audience.';
      case TenkuAICommand.rewrite:
        return '$base\nYour task: Rewrite the provided text to be clearer, more professional, and better structured.';
      case TenkuAICommand.freestyle:
        return '$base\nAnswer the user\'s question helpfully. If they gave you chat context, use it to give a relevant answer.';
    }
  }

  // ─── Main: respond to @TenkuAI mention ───────────────────
  Future<String> respond({
    required String userMessage,
    required TenkuAICommand command,
    String? channelId,
    String? chatId,
    List<AIMessage> conversationHistory = const [],
  }) async {
    // Build context from channel/chat messages
    List<String> contextLines = [];
    if (channelId != null && channelId.isNotEmpty) {
      contextLines = await _getChannelContext(channelId);
    } else if (chatId != null && chatId.isNotEmpty) {
      contextLines = await _getChatContext(chatId);
    }

    // Build messages array
    final messages = <Map<String, dynamic>>[];

    // Add conversation history
    for (final msg in conversationHistory) {
      messages.add(msg.toMap());
    }

    // Add context + user request
    final userContent = StringBuffer();
    if (contextLines.isNotEmpty) {
      userContent.writeln('Recent chat messages:');
      userContent.writeln('---');
      for (final line in contextLines) {
        userContent.writeln(line);
      }
      userContent.writeln('---');
      userContent.writeln('');
    }
    userContent.write(userMessage.replaceAll('@TenkuAI', '').trim());

    messages.add({'role': 'user', 'content': userContent.toString()});

    // Call Claude API
    return await _callClaude(
      systemPrompt: _buildSystemPrompt(command),
      messages: messages,
    );
  }

  // ─── Direct message to AI (for AI chat thread) ───────────
  Future<String> chat({
    required List<AIMessage> history,
    required String newMessage,
  }) async {
    final messages = [
      ...history.map((m) => m.toMap()),
      {'role': 'user', 'content': newMessage},
    ];

    return await _callClaude(
      systemPrompt: '''You are TenkuAI, a smart, friendly AI assistant inside the Tenku chat app.
Be helpful, concise, and conversational. Format nicely for mobile chat.''',
      messages: messages,
    );
  }

  // ─── HTTP call to Claude API ─────────────────────────────
  Future<String> _callClaude({
    required String systemPrompt,
    required List<Map<String, dynamic>> messages,
    int maxTokens = 1024,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_apiBase),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _claudeApiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': maxTokens,
          'system': systemPrompt,
          'messages': messages,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final content = data['content'] as List<dynamic>;
        if (content.isNotEmpty && content.first['type'] == 'text') {
          return content.first['text'] as String;
        }
        return 'Sorry, I could not generate a response.';
      } else {
        final error = jsonDecode(response.body);
        throw Exception('Claude API error: ${error['error']?['message'] ?? response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('YOUR_CLAUDE_API_KEY')) {
        return '⚠️ TenkuAI is not configured yet.\n\nTo enable it:\n1. Get an API key from console.anthropic.com\n2. Add it to lib/services/ai_service.dart';
      }
      return '❌ TenkuAI is temporarily unavailable. Please try again later.';
    }
  }

  // ─── Save AI conversation to Firestore ───────────────────
  Future<void> saveAIMessage({
    required String userId,
    required String role,
    required String content,
    required String threadId,
  }) async {
    await _db
        .collection('ai_threads')
        .doc(threadId)
        .collection('messages')
        .add({
      'userId': userId,
      'role': role,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> streamAIThread(String threadId) {
    return _db
        .collection('ai_threads')
        .doc(threadId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((s) => s.docs
            .map((d) => {...d.data(), 'id': d.id})
            .toList());
  }
}
