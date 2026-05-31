import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, video, file, system }
enum MessageStatus { sending, sent, delivered, read }

class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;
  final String? replyToId;
  final String? replyToContent;
  final String? replyToSender;
  final Map<String, List<String>> reactions; // emoji -> [userIds]
  final bool isEdited;
  final bool isDeleted;
  final String? mediaUrl;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    required this.timestamp,
    this.replyToId,
    this.replyToContent,
    this.replyToSender,
    this.reactions = const {},
    this.isEdited = false,
    this.isDeleted = false,
    this.mediaUrl,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderAvatar: map['senderAvatar'],
      content: map['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'text'),
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'sent'),
        orElse: () => MessageStatus.sent,
      ),
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      replyToId: map['replyToId'],
      replyToContent: map['replyToContent'],
      replyToSender: map['replyToSender'],
      reactions: Map<String, List<String>>.from(
        (map['reactions'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, List<String>.from(v)),
        ),
      ),
      isEdited: map['isEdited'] ?? false,
      isDeleted: map['isDeleted'] ?? false,
      mediaUrl: map['mediaUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'content': content,
      'type': type.name,
      'status': status.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'replyToId': replyToId,
      'replyToContent': replyToContent,
      'replyToSender': replyToSender,
      'reactions': reactions,
      'isEdited': isEdited,
      'isDeleted': isDeleted,
      'mediaUrl': mediaUrl,
    };
  }

  MessageModel copyWith({
    String? content,
    MessageStatus? status,
    Map<String, List<String>>? reactions,
    bool? isEdited,
    bool? isDeleted,
  }) {
    return MessageModel(
      id: id,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      content: content ?? this.content,
      type: type,
      status: status ?? this.status,
      timestamp: timestamp,
      replyToId: replyToId,
      replyToContent: replyToContent,
      replyToSender: replyToSender,
      reactions: reactions ?? this.reactions,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      mediaUrl: mediaUrl,
    );
  }
}
