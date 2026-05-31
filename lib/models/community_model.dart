import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'message_model.dart';

enum ChannelType { text, voice, announcement }

class ChannelModel extends Equatable {
  final String id;
  final String communityId;
  final String name;
  final String? description;
  final ChannelType type;
  final int position;
  final DateTime createdAt;
  final int unreadCount;

  const ChannelModel({
    required this.id,
    required this.communityId,
    required this.name,
    this.description,
    this.type = ChannelType.text,
    this.position = 0,
    required this.createdAt,
    this.unreadCount = 0,
  });

  factory ChannelModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChannelModel(
      id: doc.id,
      communityId: data['communityId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'],
      type: ChannelType.values.firstWhere(
        (e) => e.name == (data['type'] ?? 'text'),
        orElse: () => ChannelType.text,
      ),
      position: data['position'] ?? 0,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      unreadCount: data['unreadCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'communityId': communityId,
      'name': name,
      'description': description,
      'type': type.name,
      'position': position,
      'createdAt': Timestamp.fromDate(createdAt),
      'unreadCount': unreadCount,
    };
  }

  String get prefix {
    switch (type) {
      case ChannelType.text: return '#';
      case ChannelType.voice: return '🎤';
      case ChannelType.announcement: return '📢';
    }
  }

  @override
  List<Object?> get props => [id, name, type, position];
}

enum MemberRole { owner, admin, moderator, member }

class MemberModel {
  final String userId;
  final MemberRole role;
  final DateTime joinedAt;
  final String? nickname;

  const MemberModel({
    required this.userId,
    this.role = MemberRole.member,
    required this.joinedAt,
    this.nickname,
  });

  factory MemberModel.fromMap(Map<String, dynamic> map) {
    return MemberModel(
      userId: map['userId'] ?? '',
      role: MemberRole.values.firstWhere(
        (e) => e.name == (map['role'] ?? 'member'),
        orElse: () => MemberRole.member,
      ),
      joinedAt: map['joinedAt'] != null
          ? (map['joinedAt'] as Timestamp).toDate()
          : DateTime.now(),
      nickname: map['nickname'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'role': role.name,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'nickname': nickname,
    };
  }
}

class CommunityModel extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? iconUrl;
  final String? bannerUrl;
  final String ownerId;
  final List<String> memberIds;
  final List<String> adminIds;
  final List<String> moderatorIds;
  final bool isPublic;
  final bool requiresApproval;
  final int memberCount;
  final DateTime createdAt;
  final List<String> tags;
  final String? inviteCode;

  const CommunityModel({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
    this.bannerUrl,
    required this.ownerId,
    this.memberIds = const [],
    this.adminIds = const [],
    this.moderatorIds = const [],
    this.isPublic = true,
    this.requiresApproval = false,
    this.memberCount = 0,
    required this.createdAt,
    this.tags = const [],
    this.inviteCode,
  });

  factory CommunityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommunityModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      iconUrl: data['iconUrl'],
      bannerUrl: data['bannerUrl'],
      ownerId: data['ownerId'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      adminIds: List<String>.from(data['adminIds'] ?? []),
      moderatorIds: List<String>.from(data['moderatorIds'] ?? []),
      isPublic: data['isPublic'] ?? true,
      requiresApproval: data['requiresApproval'] ?? false,
      memberCount: data['memberCount'] ?? 0,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      tags: List<String>.from(data['tags'] ?? []),
      inviteCode: data['inviteCode'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'iconUrl': iconUrl,
      'bannerUrl': bannerUrl,
      'ownerId': ownerId,
      'memberIds': memberIds,
      'adminIds': adminIds,
      'moderatorIds': moderatorIds,
      'isPublic': isPublic,
      'requiresApproval': requiresApproval,
      'memberCount': memberCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'tags': tags,
      'inviteCode': inviteCode,
    };
  }

  bool isMember(String userId) => memberIds.contains(userId);
  bool isOwner(String userId) => ownerId == userId;
  bool isAdmin(String userId) => adminIds.contains(userId) || isOwner(userId);
  bool isModerator(String userId) => moderatorIds.contains(userId) || isAdmin(userId);

  @override
  List<Object?> get props => [id, name, memberCount, iconUrl];
}
