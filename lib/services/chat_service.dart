import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // Get or Create Direct Chat
  Future<String> getOrCreateDirectChat(String currentUserId, String otherUserId) async {
    // Check if chat exists
    final query = await _firestore
        .collection('chats')
        .where('participantIds', arrayContains: currentUserId)
        .where('isGroup', isEqualTo: false)
        .get();

    for (final doc in query.docs) {
      final ids = List<String>.from(doc['participantIds']);
      if (ids.contains(otherUserId)) {
        return doc.id;
      }
    }

    // Get both user profiles
    final currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
    final otherUserDoc = await _firestore.collection('users').doc(otherUserId).get();

    final currentUser = UserModel.fromFirestore(currentUserDoc);
    final otherUser = UserModel.fromFirestore(otherUserDoc);

    // Create new chat
    final chatRef = _firestore.collection('chats').doc();
    await chatRef.set({
      'participantIds': [currentUserId, otherUserId],
      'participantNames': {
        currentUserId: currentUser.displayName,
        otherUserId: otherUser.displayName,
      },
      'participantAvatars': {
        currentUserId: currentUser.avatarUrl,
        otherUserId: otherUser.avatarUrl,
      },
      'isGroup': false,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCounts': {currentUserId: 0, otherUserId: 0},
      'isTyping': {currentUserId: false, otherUserId: false},
      'createdAt': FieldValue.serverTimestamp(),
    });

    return chatRef.id;
  }

  // Stream Chats for User
  Stream<List<ChatModel>> streamChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final chats = <ChatModel>[];
      for (final doc in snapshot.docs) {
        final chat = ChatModel.fromFirestore(doc);

        // Get last message
        final lastMsgQuery = await _firestore
            .collection('chats')
            .doc(doc.id)
            .collection('messages')
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();

        MessageModel? lastMessage;
        if (lastMsgQuery.docs.isNotEmpty) {
          lastMessage = MessageModel.fromFirestore(lastMsgQuery.docs.first);
        }

        chats.add(ChatModel(
          id: chat.id,
          participantIds: chat.participantIds,
          participantNames: chat.participantNames,
          participantAvatars: chat.participantAvatars,
          lastMessage: lastMessage,
          lastMessageAt: chat.lastMessageAt,
          unreadCounts: chat.unreadCounts,
          isTyping: chat.isTyping,
          isGroup: chat.isGroup,
          groupName: chat.groupName,
          groupAvatar: chat.groupAvatar,
          createdAt: chat.createdAt,
        ));
      }
      return chats;
    });
  }

  // Stream Messages
  Stream<List<MessageModel>> streamMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc))
            .toList());
  }

  // Send Message
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    String? senderAvatar,
    required String content,
    MessageType type = MessageType.text,
    String? replyToId,
    String? replyToContent,
    String? replyToSenderName,
    String? mediaUrl,
    String? fileName,
    int? fileSize,
  }) async {
    final messageId = _uuid.v4();
    final batch = _firestore.batch();

    final messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);

    batch.set(messageRef, {
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'content': content,
      'type': type.name,
      'status': MessageStatus.sent.name,
      'createdAt': FieldValue.serverTimestamp(),
      'isDeleted': false,
      'replyToId': replyToId,
      'replyToContent': replyToContent,
      'replyToSenderName': replyToSenderName,
      'reactions': [],
      'mediaUrl': mediaUrl,
      'fileName': fileName,
      'fileSize': fileSize,
    });

    // Update chat's last message time
    final chatRef = _firestore.collection('chats').doc(chatId);
    batch.update(chatRef, {
      'lastMessageAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    // Mark messages as delivered for other participants
    final chatDoc = await chatRef.get();
    final participantIds = List<String>.from(chatDoc['participantIds'] ?? []);
    for (final participantId in participantIds) {
      if (participantId != senderId) {
        await chatRef.update({
          'unreadCounts.$participantId': FieldValue.increment(1),
        });
      }
    }
  }

  // Edit Message
  Future<void> editMessage({
    required String chatId,
    required String messageId,
    required String newContent,
  }) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'content': newContent,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete Message
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  }) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'isDeleted': true,
      'content': 'This message was deleted',
    });
  }

  // Add Reaction
  Future<void> addReaction({
    required String chatId,
    required String messageId,
    required String emoji,
    required String userId,
  }) async {
    final msgRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);

    final doc = await msgRef.get();
    final reactions = List<Map<String, dynamic>>.from(doc['reactions'] ?? []);

    final existingIndex = reactions.indexWhere((r) => r['emoji'] == emoji);
    if (existingIndex >= 0) {
      final userIds = List<String>.from(reactions[existingIndex]['userIds']);
      if (userIds.contains(userId)) {
        userIds.remove(userId);
      } else {
        userIds.add(userId);
      }
      if (userIds.isEmpty) {
        reactions.removeAt(existingIndex);
      } else {
        reactions[existingIndex]['userIds'] = userIds;
      }
    } else {
      reactions.add({'emoji': emoji, 'userIds': [userId]});
    }

    await msgRef.update({'reactions': reactions});
  }

  // Mark Messages as Read
  Future<void> markAsRead({required String chatId, required String userId}) async {
    await _firestore.collection('chats').doc(chatId).update({
      'unreadCounts.$userId': 0,
    });

    // Update message statuses
    final unreadMessages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('senderId', isNotEqualTo: userId)
        .where('status', isEqualTo: MessageStatus.delivered.name)
        .get();

    final batch = _firestore.batch();
    for (final doc in unreadMessages.docs) {
      batch.update(doc.reference, {'status': MessageStatus.read.name});
    }
    await batch.commit();
  }

  // Update Typing Status
  Future<void> updateTypingStatus({
    required String chatId,
    required String userId,
    required bool isTyping,
  }) async {
    await _firestore.collection('chats').doc(chatId).update({
      'isTyping.$userId': isTyping,
    });
  }

  // Stream Typing Status
  Stream<Map<String, bool>> streamTypingStatus(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .map((doc) => Map<String, bool>.from(doc['isTyping'] ?? {}));
  }
}
