import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/phase3_models.dart';

class PollService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // ─── Create poll (stored inside a message) ───────────────
  Future<PollModel> createPoll({
    required String chatId,
    required String creatorId,
    required String creatorName,
    required String question,
    required List<String> optionTexts,
    bool isMultipleChoice = false,
    bool isAnonymous = false,
    Duration? expireAfter,
    bool isCommunityPoll = false,
  }) async {
    final pollId = _uuid.v4();
    final options = optionTexts.asMap().entries.map((e) => PollOption(
      id: _uuid.v4(),
      text: e.value,
    )).toList();

    final poll = PollModel(
      id: pollId,
      chatId: isCommunityPoll ? '' : chatId,
      channelId: isCommunityPoll ? chatId : '',
      creatorId: creatorId,
      creatorName: creatorName,
      question: question,
      options: options,
      isMultipleChoice: isMultipleChoice,
      isAnonymous: isAnonymous,
      createdAt: DateTime.now(),
      expiresAt: expireAfter != null ? DateTime.now().add(expireAfter) : null,
      isCommunityPoll: isCommunityPoll,
    );

    // Save poll doc
    await _db.collection('polls').doc(pollId).set(poll.toMap());

    // Also create a message referencing this poll
    final col = isCommunityPoll
        ? _db.collection('channels').doc(chatId).collection('messages')
        : _db.collection('chats').doc(chatId).collection('messages');

    await col.add({
      'chatId': chatId,
      'senderId': creatorId,
      'senderName': creatorName,
      'content': '📊 Poll: $question',
      'type': 'text',
      'status': 'sent',
      'createdAt': FieldValue.serverTimestamp(),
      'isDeleted': false,
      'reactions': [],
      'pollId': pollId,
      'isPoll': true,
    });

    return poll;
  }

  // ─── Vote on a poll ──────────────────────────────────────
  Future<void> vote({
    required String pollId,
    required String optionId,
    required String userId,
    bool isMultipleChoice = false,
  }) async {
    final ref = _db.collection('polls').doc(pollId);
    final doc = await ref.get();
    if (!doc.exists) return;

    final poll = PollModel.fromFirestore(doc);
    if (poll.isClosed) return;

    final options = poll.options.map((opt) {
      List<String> votes = List<String>.from(opt.votes);

      if (!isMultipleChoice) {
        // Remove vote from all options first (single choice)
        votes.remove(userId);
      }

      if (opt.id == optionId) {
        if (votes.contains(userId)) {
          // Unvote (toggle)
          votes.remove(userId);
        } else {
          votes.add(userId);
        }
      }

      return {'id': opt.id, 'text': opt.text, 'votes': votes};
    }).toList();

    await ref.update({'options': options});
  }

  // ─── Close poll ──────────────────────────────────────────
  Future<void> closePoll(String pollId) async {
    await _db.collection('polls').doc(pollId).update({'isClosed': true});
  }

  // ─── Stream poll ─────────────────────────────────────────
  Stream<PollModel?> streamPoll(String pollId) {
    return _db.collection('polls').doc(pollId).snapshots().map(
        (d) => d.exists ? PollModel.fromFirestore(d) : null);
  }

  // ─── Stream polls in channel ─────────────────────────────
  Stream<List<PollModel>> streamChannelPolls(String channelId) {
    return _db
        .collection('polls')
        .where('channelId', isEqualTo: channelId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => PollModel.fromFirestore(d)).toList());
  }
}
