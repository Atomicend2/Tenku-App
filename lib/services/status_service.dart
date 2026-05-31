import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/status_model.dart';

class StatusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Create Text Status
  Future<void> createTextStatus({
    required String userId,
    required String userName,
    String? userAvatar,
    required String text,
    String? backgroundColor,
  }) async {
    await _firestore.collection('statuses').add({
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'type': StatusType.text.name,
      'text': text,
      'backgroundColor': backgroundColor ?? '#6C63FF',
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24))),
      'viewedBy': [],
      'isActive': true,
    });
  }

  // Create Image Status
  Future<void> createImageStatus({
    required String userId,
    required String userName,
    String? userAvatar,
    required File imageFile,
    String? caption,
  }) async {
    final ref = _storage.ref().child('statuses/$userId/${DateTime.now().millisecondsSinceEpoch}');
    await ref.putFile(imageFile);
    final url = await ref.getDownloadURL();

    await _firestore.collection('statuses').add({
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'type': StatusType.image.name,
      'mediaUrl': url,
      'text': caption,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24))),
      'viewedBy': [],
      'isActive': true,
    });
  }

  // Stream Recent Statuses (from friends/contacts)
  Stream<List<StatusModel>> streamStatuses(String currentUserId) {
    final expiry = Timestamp.fromDate(DateTime.now());
    return _firestore
        .collection('statuses')
        .where('expiresAt', isGreaterThan: expiry)
        .where('isActive', isEqualTo: true)
        .orderBy('expiresAt', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => StatusModel.fromFirestore(d)).toList());
  }

  // Stream My Statuses
  Stream<List<StatusModel>> streamMyStatuses(String userId) {
    final expiry = Timestamp.fromDate(DateTime.now());
    return _firestore
        .collection('statuses')
        .where('userId', isEqualTo: userId)
        .where('expiresAt', isGreaterThan: expiry)
        .orderBy('expiresAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => StatusModel.fromFirestore(d)).toList());
  }

  // Mark Status as Viewed
  Future<void> markAsViewed({
    required String statusId,
    required String viewerId,
  }) async {
    await _firestore.collection('statuses').doc(statusId).update({
      'viewedBy': FieldValue.arrayUnion([viewerId]),
    });
  }

  // Group statuses by user
  List<UserStatusGroup> groupStatusesByUser(
    List<StatusModel> statuses,
    String currentUserId,
  ) {
    final Map<String, UserStatusGroup> groupedMap = {};

    for (final status in statuses) {
      if (!groupedMap.containsKey(status.userId)) {
        groupedMap[status.userId] = UserStatusGroup(
          userId: status.userId,
          userName: status.userName,
          userAvatar: status.userAvatar,
          statuses: [],
          isViewed: status.hasViewed(currentUserId),
        );
      }
      groupedMap[status.userId]!.statuses.add(status);
      if (!status.hasViewed(currentUserId)) {
        groupedMap[status.userId]!.isViewed = false;
      }
    }

    // Current user's statuses first
    final groups = groupedMap.values.toList();
    groups.sort((a, b) {
      if (a.userId == currentUserId) return -1;
      if (b.userId == currentUserId) return 1;
      if (a.isViewed && !b.isViewed) return 1;
      if (!a.isViewed && b.isViewed) return -1;
      return 0;
    });

    return groups;
  }
}
