// ============================================================
// PHASE 2 — CALL SERVICE
// Uses Agora RTC Engine for voice & video calls.
// Add to pubspec.yaml:
//   agora_rtc_engine: ^6.3.2
//   permission_handler: ^11.3.1
// Get a free Agora App ID at https://console.agora.io
// Set AGORA_APP_ID in your .env or constants file.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

enum CallType { voice, video }
enum CallStatus { ringing, active, ended, declined, missed, failed }

class CallModel {
  final String id;
  final String callerId;
  final String callerName;
  final String? callerAvatar;
  final String receiverId;
  final String receiverName;
  final String? receiverAvatar;
  final CallType type;
  final CallStatus status;
  final DateTime createdAt;
  final DateTime? answeredAt;
  final DateTime? endedAt;
  final String channelId;

  CallModel({
    required this.id,
    required this.callerId,
    required this.callerName,
    this.callerAvatar,
    required this.receiverId,
    required this.receiverName,
    this.receiverAvatar,
    required this.type,
    required this.status,
    required this.createdAt,
    this.answeredAt,
    this.endedAt,
    required this.channelId,
  });

  factory CallModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CallModel(
      id: doc.id,
      callerId: d['callerId'] ?? '',
      callerName: d['callerName'] ?? '',
      callerAvatar: d['callerAvatar'],
      receiverId: d['receiverId'] ?? '',
      receiverName: d['receiverName'] ?? '',
      receiverAvatar: d['receiverAvatar'],
      type: CallType.values.firstWhere((e) => e.name == (d['type'] ?? 'voice'), orElse: () => CallType.voice),
      status: CallStatus.values.firstWhere((e) => e.name == (d['status'] ?? 'ringing'), orElse: () => CallStatus.ringing),
      createdAt: d['createdAt'] != null ? (d['createdAt'] as Timestamp).toDate() : DateTime.now(),
      answeredAt: d['answeredAt'] != null ? (d['answeredAt'] as Timestamp).toDate() : null,
      endedAt: d['endedAt'] != null ? (d['endedAt'] as Timestamp).toDate() : null,
      channelId: d['channelId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'callerId': callerId,
        'callerName': callerName,
        'callerAvatar': callerAvatar,
        'receiverId': receiverId,
        'receiverName': receiverName,
        'receiverAvatar': receiverAvatar,
        'type': type.name,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'answeredAt': answeredAt != null ? Timestamp.fromDate(answeredAt!) : null,
        'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
        'channelId': channelId,
      };

  int get durationSeconds =>
      (answeredAt != null && endedAt != null) ? endedAt!.difference(answeredAt!).inSeconds : 0;

  String get formattedDuration {
    final s = durationSeconds;
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }
}

class CallService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // AGORA APP ID — replace with your own from https://console.agora.io
  static const String agoraAppId = 'YOUR_AGORA_APP_ID';

  Future<CallModel> initiateCall({
    required String callerId,
    required String callerName,
    String? callerAvatar,
    required String receiverId,
    required String receiverName,
    String? receiverAvatar,
    required CallType type,
  }) async {
    final channelId = _uuid.v4().replaceAll('-', '').substring(0, 16);
    final callRef = _db.collection('calls').doc();

    final call = CallModel(
      id: callRef.id,
      callerId: callerId,
      callerName: callerName,
      callerAvatar: callerAvatar,
      receiverId: receiverId,
      receiverName: receiverName,
      receiverAvatar: receiverAvatar,
      type: type,
      status: CallStatus.ringing,
      createdAt: DateTime.now(),
      channelId: channelId,
    );

    await callRef.set(call.toMap());
    return call;
  }

  Future<void> answerCall(String callId) async {
    await _db.collection('calls').doc(callId).update({
      'status': CallStatus.active.name,
      'answeredAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> declineCall(String callId) async {
    await _db.collection('calls').doc(callId).update({
      'status': CallStatus.declined.name,
      'endedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> endCall(String callId) async {
    await _db.collection('calls').doc(callId).update({
      'status': CallStatus.ended.name,
      'endedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<CallModel?> streamIncomingCall(String userId) {
    return _db
        .collection('calls')
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: CallStatus.ringing.name)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((s) => s.docs.isEmpty ? null : CallModel.fromFirestore(s.docs.first));
  }

  Stream<CallModel?> streamCallStatus(String callId) {
    return _db.collection('calls').doc(callId).snapshots().map((d) => d.exists ? CallModel.fromFirestore(d) : null);
  }

  Stream<List<CallModel>> streamCallHistory(String userId) {
    return _db
        .collection('calls')
        .where('callerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map((s) => s.docs.map((d) => CallModel.fromFirestore(d)).toList());
  }
}
