import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/community_model.dart';
import '../models/message_model.dart';

class CommunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // Create Community
  Future<CommunityModel> createCommunity({
    required String name,
    required String ownerId,
    String? description,
    String? iconUrl,
    bool isPublic = true,
  }) async {
    final communityRef = _firestore.collection('communities').doc();
    final inviteCode = _generateInviteCode();

    final community = {
      'name': name,
      'description': description,
      'iconUrl': iconUrl,
      'ownerId': ownerId,
      'memberIds': [ownerId],
      'adminIds': [ownerId],
      'moderatorIds': [],
      'isPublic': isPublic,
      'requiresApproval': false,
      'memberCount': 1,
      'createdAt': FieldValue.serverTimestamp(),
      'tags': [],
      'inviteCode': inviteCode,
    };

    await communityRef.set(community);

    // Create default channels
    await _createDefaultChannels(communityRef.id, ownerId);

    // Add to user's communities
    await _firestore.collection('users').doc(ownerId).update({
      'communityIds': FieldValue.arrayUnion([communityRef.id]),
    });

    final doc = await communityRef.get();
    return CommunityModel.fromFirestore(doc);
  }

  // Create Default Channels
  Future<void> _createDefaultChannels(String communityId, String ownerId) async {
    final textChannels = [
      {'name': 'general', 'type': 'text', 'position': 0},
      {'name': 'announcements', 'type': 'announcement', 'position': 1},
    ];
    final voiceChannels = [
      {'name': 'General VC', 'type': 'voice', 'position': 0},
      {'name': 'Chill Room', 'type': 'voice', 'position': 1},
    ];

    final batch = _firestore.batch();
    for (final ch in [...textChannels, ...voiceChannels]) {
      final ref = _firestore.collection('channels').doc();
      batch.set(ref, {
        'communityId': communityId,
        'name': ch['name'],
        'type': ch['type'],
        'position': ch['position'],
        'createdAt': FieldValue.serverTimestamp(),
        'description': null,
      });
    }
    await batch.commit();
  }

  // Get Community
  Future<CommunityModel?> getCommunity(String communityId) async {
    final doc = await _firestore.collection('communities').doc(communityId).get();
    if (doc.exists) {
      return CommunityModel.fromFirestore(doc);
    }
    return null;
  }

  // Stream Communities for User
  Stream<List<CommunityModel>> streamUserCommunities(String userId) {
    return _firestore
        .collection('communities')
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => CommunityModel.fromFirestore(d)).toList());
  }

  // Stream Public Communities
  Stream<List<CommunityModel>> streamPublicCommunities() {
    return _firestore
        .collection('communities')
        .where('isPublic', isEqualTo: true)
        .orderBy('memberCount', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((d) => CommunityModel.fromFirestore(d)).toList());
  }

  // Join Community
  Future<void> joinCommunity({
    required String communityId,
    required String userId,
  }) async {
    final batch = _firestore.batch();
    final communityRef = _firestore.collection('communities').doc(communityId);
    final userRef = _firestore.collection('users').doc(userId);

    batch.update(communityRef, {
      'memberIds': FieldValue.arrayUnion([userId]),
      'memberCount': FieldValue.increment(1),
    });
    batch.update(userRef, {
      'communityIds': FieldValue.arrayUnion([communityId]),
    });

    await batch.commit();
  }

  // Leave Community
  Future<void> leaveCommunity({
    required String communityId,
    required String userId,
  }) async {
    final batch = _firestore.batch();
    final communityRef = _firestore.collection('communities').doc(communityId);
    final userRef = _firestore.collection('users').doc(userId);

    batch.update(communityRef, {
      'memberIds': FieldValue.arrayRemove([userId]),
      'adminIds': FieldValue.arrayRemove([userId]),
      'memberCount': FieldValue.increment(-1),
    });
    batch.update(userRef, {
      'communityIds': FieldValue.arrayRemove([communityId]),
    });

    await batch.commit();
  }

  // Stream Channels for Community
  Stream<List<ChannelModel>> streamChannels(String communityId) {
    return _firestore
        .collection('channels')
        .where('communityId', isEqualTo: communityId)
        .orderBy('position')
        .snapshots()
        .map((snap) => snap.docs.map((d) => ChannelModel.fromFirestore(d)).toList());
  }

  // Create Channel
  Future<ChannelModel> createChannel({
    required String communityId,
    required String name,
    ChannelType type = ChannelType.text,
    String? description,
    int position = 0,
  }) async {
    final ref = _firestore.collection('channels').doc();
    await ref.set({
      'communityId': communityId,
      'name': name,
      'type': type.name,
      'description': description,
      'position': position,
      'createdAt': FieldValue.serverTimestamp(),
    });
    final doc = await ref.get();
    return ChannelModel.fromFirestore(doc);
  }

  // Stream Channel Messages
  Stream<List<MessageModel>> streamChannelMessages(String channelId) {
    return _firestore
        .collection('channels')
        .doc(channelId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((d) => MessageModel.fromFirestore(d)).toList());
  }

  // Send Channel Message
  Future<void> sendChannelMessage({
    required String channelId,
    required String communityId,
    required String senderId,
    required String senderName,
    String? senderAvatar,
    required String content,
    MessageType type = MessageType.text,
    String? replyToId,
    String? replyToContent,
    String? replyToSenderName,
  }) async {
    final messageId = _uuid.v4();
    await _firestore
        .collection('channels')
        .doc(channelId)
        .collection('messages')
        .doc(messageId)
        .set({
      'chatId': channelId,
      'communityId': communityId,
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
    });
  }

  // Add Reaction to Channel Message
  Future<void> addReaction({
    required String channelId,
    required String messageId,
    required String emoji,
    required String userId,
  }) async {
    final msgRef = _firestore
        .collection('channels')
        .doc(channelId)
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

  // Search Communities
  Future<List<CommunityModel>> searchCommunities(String query) async {
    final snap = await _firestore
        .collection('communities')
        .where('isPublic', isEqualTo: true)
        .orderBy('name')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .limit(20)
        .get();
    return snap.docs.map((d) => CommunityModel.fromFirestore(d)).toList();
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = List.generate(8, (i) => chars[i % chars.length]);
    return random.join();
  }
}
