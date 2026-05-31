import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum NotificationType {
  newMessage,
  reply,
  reaction,
  friendRequest,
  friendAccepted,
  communityInvite,
  communityJoin,
  mention,
}

class NotificationModel extends Equatable {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final String? imageUrl;
  final String? actionId;
  final String? actionRoute;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.imageUrl,
    this.actionId,
    this.actionRoute,
    this.isRead = false,
    required this.createdAt,
    this.metadata = const {},
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == (data['type'] ?? 'newMessage'),
        orElse: () => NotificationType.newMessage,
      ),
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      imageUrl: data['imageUrl'],
      actionId: data['actionId'],
      actionRoute: data['actionRoute'],
      isRead: data['isRead'] ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.name,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'actionId': actionId,
      'actionRoute': actionRoute,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'metadata': metadata,
    };
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      userId: userId,
      type: type,
      title: title,
      body: body,
      imageUrl: imageUrl,
      actionId: actionId,
      actionRoute: actionRoute,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      metadata: metadata,
    );
  }

  @override
  List<Object?> get props => [id, isRead, createdAt];
}
