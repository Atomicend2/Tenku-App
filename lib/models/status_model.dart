import 'package:cloud_firestore/cloud_firestore.dart';

enum StatusType { text, image, video }

class StatusModel {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final StatusType type;
  final String? content; // text content or caption
  final String? mediaUrl;
  final String backgroundColor;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String> viewedBy;

  StatusModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.type,
    this.content,
    this.mediaUrl,
    this.backgroundColor = '#6C63FF',
    required this.createdAt,
    required this.expiresAt,
    this.viewedBy = const [],
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory StatusModel.fromMap(Map<String, dynamic> map, String id) {
    return StatusModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userAvatar: map['userAvatar'],
      type: StatusType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'text'),
        orElse: () => StatusType.text,
      ),
      content: map['content'],
      mediaUrl: map['mediaUrl'],
      backgroundColor: map['backgroundColor'] ?? '#6C63FF',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      expiresAt: map['expiresAt'] != null
          ? (map['expiresAt'] as Timestamp).toDate()
          : DateTime.now().add(const Duration(hours: 24)),
      viewedBy: List<String>.from(map['viewedBy'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'type': type.name,
      'content': content,
      'mediaUrl': mediaUrl,
      'backgroundColor': backgroundColor,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'viewedBy': viewedBy,
    };
  }
}

class ConversationModel {
  final String id;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final Map<String, String?> participantAvatars;
  final String? lastMessage;
  final String? lastMessageSenderId;
  final DateTime? lastMessageTime;
  final Map<String, int> unreadCount;
  final Map<String, bool> typing;

  ConversationModel({
    required this.id,
    required this.participantIds,
    this.participantNames = const {},
    this.participantAvatars = const {},
    this.lastMessage,
    this.lastMessageSenderId,
    this.lastMessageTime,
    this.unreadCount = const {},
    this.typing = const {},
  });

  factory ConversationModel.fromMap(Map<String, dynamic> map, String id) {
    return ConversationModel(
      id: id,
      participantIds: List<String>.from(map['participantIds'] ?? []),
      participantNames: Map<String, String>.from(map['participantNames'] ?? {}),
      participantAvatars: Map<String, String?>.from(map['participantAvatars'] ?? {}),
      lastMessage: map['lastMessage'],
      lastMessageSenderId: map['lastMessageSenderId'],
      lastMessageTime: map['lastMessageTime'] != null
          ? (map['lastMessageTime'] as Timestamp).toDate()
          : null,
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
      typing: Map<String, bool>.from(map['typing'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participantIds': participantIds,
      'participantNames': participantNames,
      'participantAvatars': participantAvatars,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageTime': lastMessageTime != null
          ? Timestamp.fromDate(lastMessageTime!)
          : null,
      'unreadCount': unreadCount,
      'typing': typing,
    };
  }
}
