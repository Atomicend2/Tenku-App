import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/phase3_models.dart';

class EventService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<EventModel> createEvent({
    required String communityId,
    required String channelId,
    required String creatorId,
    required String creatorName,
    required String title,
    String? description,
    String? location,
    required DateTime startTime,
    DateTime? endTime,
    String? coverImageUrl,
  }) async {
    final ref = _db.collection('events').doc();
    final event = EventModel(
      id: ref.id,
      communityId: communityId,
      channelId: channelId,
      creatorId: creatorId,
      creatorName: creatorName,
      title: title,
      description: description,
      location: location,
      startTime: startTime,
      endTime: endTime,
      coverImageUrl: coverImageUrl,
      attendeeIds: [creatorId],
      createdAt: DateTime.now(),
    );
    await ref.set(event.toMap());
    return event;
  }

  Future<void> rsvp({
    required String eventId,
    required String userId,
    required String response, // 'going' | 'maybe' | 'declined'
  }) async {
    final ref = _db.collection('events').doc(eventId);
    // Remove from all lists first
    await ref.update({
      'attendeeIds': FieldValue.arrayRemove([userId]),
      'maybeIds': FieldValue.arrayRemove([userId]),
      'declinedIds': FieldValue.arrayRemove([userId]),
    });
    // Add to correct list
    switch (response) {
      case 'going': await ref.update({'attendeeIds': FieldValue.arrayUnion([userId])}); break;
      case 'maybe': await ref.update({'maybeIds': FieldValue.arrayUnion([userId])}); break;
      case 'declined': await ref.update({'declinedIds': FieldValue.arrayUnion([userId])}); break;
    }
  }

  Stream<List<EventModel>> streamCommunityEvents(String communityId) {
    return _db
        .collection('events')
        .where('communityId', isEqualTo: communityId)
        .orderBy('startTime')
        .snapshots()
        .map((s) => s.docs.map((d) => EventModel.fromFirestore(d)).toList());
  }

  Stream<List<EventModel>> streamUpcomingEvents(String communityId) {
    return _db
        .collection('events')
        .where('communityId', isEqualTo: communityId)
        .where('startTime', isGreaterThan: Timestamp.fromDate(DateTime.now()))
        .orderBy('startTime')
        .limit(20)
        .snapshots()
        .map((s) => s.docs.map((d) => EventModel.fromFirestore(d)).toList());
  }

  Future<void> deleteEvent(String eventId) async {
    await _db.collection('events').doc(eventId).delete();
  }
}
