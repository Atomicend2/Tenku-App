import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String username;
  final String displayName;
  final String bio;
  final String? avatarUrl;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime createdAt;
  final List<String> communityIds;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    required this.displayName,
    this.bio = '',
    this.avatarUrl,
    this.isOnline = false,
    this.lastSeen,
    required this.createdAt,
    this.communityIds = const [],
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      displayName: map['displayName'] ?? '',
      bio: map['bio'] ?? '',
      avatarUrl: map['avatarUrl'],
      isOnline: map['isOnline'] ?? false,
      lastSeen: map['lastSeen'] != null
          ? (map['lastSeen'] as Timestamp).toDate()
          : null,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      communityIds: List<String>.from(map['communityIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'displayName': displayName,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'isOnline': isOnline,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'communityIds': communityIds,
    };
  }

  UserModel copyWith({
    String? displayName,
    String? username,
    String? bio,
    String? avatarUrl,
    bool? isOnline,
    DateTime? lastSeen,
    List<String>? communityIds,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt,
      communityIds: communityIds ?? this.communityIds,
    );
  }
}
