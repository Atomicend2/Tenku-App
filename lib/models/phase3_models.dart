// ============================================================
// PHASE 3 MODELS
// ============================================================
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

// ─── Poll ────────────────────────────────────────────────────

class PollOption {
  final String id;
  final String text;
  final List<String> votes; // user IDs who voted

  const PollOption({required this.id, required this.text, this.votes = const []});

  factory PollOption.fromMap(Map<String, dynamic> m) => PollOption(
        id: m['id'] ?? '',
        text: m['text'] ?? '',
        votes: List<String>.from(m['votes'] ?? []),
      );

  Map<String, dynamic> toMap() => {'id': id, 'text': text, 'votes': votes};

  int get voteCount => votes.length;
  bool hasVoted(String uid) => votes.contains(uid);
}

class PollModel extends Equatable {
  final String id;
  final String chatId;
  final String channelId;
  final String creatorId;
  final String creatorName;
  final String question;
  final List<PollOption> options;
  final bool isMultipleChoice;
  final bool isAnonymous;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isClosed;
  final bool isCommunityPoll; // true = channel poll, false = DM poll

  const PollModel({
    required this.id,
    this.chatId = '',
    this.channelId = '',
    required this.creatorId,
    required this.creatorName,
    required this.question,
    required this.options,
    this.isMultipleChoice = false,
    this.isAnonymous = false,
    required this.createdAt,
    this.expiresAt,
    this.isClosed = false,
    this.isCommunityPoll = false,
  });

  int get totalVotes => options.fold(0, (sum, o) => sum + o.voteCount);

  bool hasVoted(String uid) => options.any((o) => o.hasVoted(uid));

  double getOptionPercent(PollOption option) {
    if (totalVotes == 0) return 0;
    return option.voteCount / totalVotes;
  }

  factory PollModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PollModel(
      id: doc.id,
      chatId: d['chatId'] ?? '',
      channelId: d['channelId'] ?? '',
      creatorId: d['creatorId'] ?? '',
      creatorName: d['creatorName'] ?? '',
      question: d['question'] ?? '',
      options: (d['options'] as List<dynamic>? ?? [])
          .map((o) => PollOption.fromMap(o as Map<String, dynamic>))
          .toList(),
      isMultipleChoice: d['isMultipleChoice'] ?? false,
      isAnonymous: d['isAnonymous'] ?? false,
      createdAt: d['createdAt'] != null ? (d['createdAt'] as Timestamp).toDate() : DateTime.now(),
      expiresAt: d['expiresAt'] != null ? (d['expiresAt'] as Timestamp).toDate() : null,
      isClosed: d['isClosed'] ?? false,
      isCommunityPoll: d['isCommunityPoll'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'chatId': chatId,
        'channelId': channelId,
        'creatorId': creatorId,
        'creatorName': creatorName,
        'question': question,
        'options': options.map((o) => o.toMap()).toList(),
        'isMultipleChoice': isMultipleChoice,
        'isAnonymous': isAnonymous,
        'createdAt': Timestamp.fromDate(createdAt),
        'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
        'isClosed': isClosed,
        'isCommunityPoll': isCommunityPoll,
      };

  @override
  List<Object?> get props => [id, isClosed, options];
}

// ─── Event ───────────────────────────────────────────────────

class EventModel extends Equatable {
  final String id;
  final String communityId;
  final String channelId;
  final String creatorId;
  final String creatorName;
  final String title;
  final String? description;
  final String? location;
  final DateTime startTime;
  final DateTime? endTime;
  final String? coverImageUrl;
  final List<String> attendeeIds;
  final List<String> maybeIds;
  final List<String> declinedIds;
  final DateTime createdAt;
  final bool isRecurring;
  final String? recurrenceRule;

  const EventModel({
    required this.id,
    required this.communityId,
    required this.channelId,
    required this.creatorId,
    required this.creatorName,
    required this.title,
    this.description,
    this.location,
    required this.startTime,
    this.endTime,
    this.coverImageUrl,
    this.attendeeIds = const [],
    this.maybeIds = const [],
    this.declinedIds = const [],
    required this.createdAt,
    this.isRecurring = false,
    this.recurrenceRule,
  });

  bool isAttending(String uid) => attendeeIds.contains(uid);
  bool isMaybe(String uid) => maybeIds.contains(uid);
  bool isDeclined(String uid) => declinedIds.contains(uid);
  bool get isPast => DateTime.now().isAfter(startTime);

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      communityId: d['communityId'] ?? '',
      channelId: d['channelId'] ?? '',
      creatorId: d['creatorId'] ?? '',
      creatorName: d['creatorName'] ?? '',
      title: d['title'] ?? '',
      description: d['description'],
      location: d['location'],
      startTime: d['startTime'] != null ? (d['startTime'] as Timestamp).toDate() : DateTime.now(),
      endTime: d['endTime'] != null ? (d['endTime'] as Timestamp).toDate() : null,
      coverImageUrl: d['coverImageUrl'],
      attendeeIds: List<String>.from(d['attendeeIds'] ?? []),
      maybeIds: List<String>.from(d['maybeIds'] ?? []),
      declinedIds: List<String>.from(d['declinedIds'] ?? []),
      createdAt: d['createdAt'] != null ? (d['createdAt'] as Timestamp).toDate() : DateTime.now(),
      isRecurring: d['isRecurring'] ?? false,
      recurrenceRule: d['recurrenceRule'],
    );
  }

  Map<String, dynamic> toMap() => {
        'communityId': communityId,
        'channelId': channelId,
        'creatorId': creatorId,
        'creatorName': creatorName,
        'title': title,
        'description': description,
        'location': location,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
        'coverImageUrl': coverImageUrl,
        'attendeeIds': attendeeIds,
        'maybeIds': maybeIds,
        'declinedIds': declinedIds,
        'createdAt': Timestamp.fromDate(createdAt),
        'isRecurring': isRecurring,
        'recurrenceRule': recurrenceRule,
      };

  @override
  List<Object?> get props => [id, startTime, attendeeIds];
}

// ─── Voice Note ──────────────────────────────────────────────

class VoiceNoteModel extends Equatable {
  final String id;
  final String senderId;
  final String senderName;
  final String audioUrl;
  final int durationSeconds;
  final DateTime createdAt;
  final List<double> waveform; // amplitude samples 0.0–1.0

  const VoiceNoteModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.audioUrl,
    required this.durationSeconds,
    required this.createdAt,
    this.waveform = const [],
  });

  String get formattedDuration {
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  factory VoiceNoteModel.fromMap(Map<String, dynamic> d, String id) => VoiceNoteModel(
        id: id,
        senderId: d['senderId'] ?? '',
        senderName: d['senderName'] ?? '',
        audioUrl: d['audioUrl'] ?? '',
        durationSeconds: d['durationSeconds'] ?? 0,
        createdAt: d['createdAt'] != null ? (d['createdAt'] as Timestamp).toDate() : DateTime.now(),
        waveform: List<double>.from(d['waveform'] ?? []),
      );

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'senderName': senderName,
        'audioUrl': audioUrl,
        'durationSeconds': durationSeconds,
        'createdAt': Timestamp.fromDate(createdAt),
        'waveform': waveform,
      };

  @override
  List<Object?> get props => [id, audioUrl, durationSeconds];
}

// ─── Pinned Message ──────────────────────────────────────────

class PinnedMessageModel extends Equatable {
  final String id;
  final String chatId;
  final String messageId;
  final String messageContent;
  final String messageSenderName;
  final String pinnedById;
  final String pinnedByName;
  final DateTime pinnedAt;
  final bool isChannelPin;

  const PinnedMessageModel({
    required this.id,
    required this.chatId,
    required this.messageId,
    required this.messageContent,
    required this.messageSenderName,
    required this.pinnedById,
    required this.pinnedByName,
    required this.pinnedAt,
    this.isChannelPin = false,
  });

  factory PinnedMessageModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PinnedMessageModel(
      id: doc.id,
      chatId: d['chatId'] ?? '',
      messageId: d['messageId'] ?? '',
      messageContent: d['messageContent'] ?? '',
      messageSenderName: d['messageSenderName'] ?? '',
      pinnedById: d['pinnedById'] ?? '',
      pinnedByName: d['pinnedByName'] ?? '',
      pinnedAt: d['pinnedAt'] != null ? (d['pinnedAt'] as Timestamp).toDate() : DateTime.now(),
      isChannelPin: d['isChannelPin'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'chatId': chatId,
        'messageId': messageId,
        'messageContent': messageContent,
        'messageSenderName': messageSenderName,
        'pinnedById': pinnedById,
        'pinnedByName': pinnedByName,
        'pinnedAt': Timestamp.fromDate(pinnedAt),
        'isChannelPin': isChannelPin,
      };

  @override
  List<Object?> get props => [id, messageId, pinnedAt];
}

// ─── Role ────────────────────────────────────────────────────

enum RoleLevel { owner, admin, moderator, member }

class RoleModel extends Equatable {
  final String id;
  final String communityId;
  final String name;
  final String color; // hex
  final RoleLevel level;
  final List<String> permissions;
  final int position;
  final bool isDefault;

  const RoleModel({
    required this.id,
    required this.communityId,
    required this.name,
    this.color = '#6C63FF',
    required this.level,
    this.permissions = const [],
    this.position = 0,
    this.isDefault = false,
  });

  static const List<String> allPermissions = [
    'send_messages',
    'manage_messages',
    'manage_channels',
    'manage_community',
    'kick_members',
    'ban_members',
    'manage_roles',
    'create_polls',
    'create_events',
    'pin_messages',
    'mention_everyone',
  ];

  bool hasPermission(String perm) => level == RoleLevel.owner || permissions.contains(perm);

  factory RoleModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return RoleModel(
      id: doc.id,
      communityId: d['communityId'] ?? '',
      name: d['name'] ?? '',
      color: d['color'] ?? '#6C63FF',
      level: RoleLevel.values.firstWhere(
        (e) => e.name == (d['level'] ?? 'member'),
        orElse: () => RoleLevel.member,
      ),
      permissions: List<String>.from(d['permissions'] ?? []),
      position: d['position'] ?? 0,
      isDefault: d['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'communityId': communityId,
        'name': name,
        'color': color,
        'level': level.name,
        'permissions': permissions,
        'position': position,
        'isDefault': isDefault,
      };

  @override
  List<Object?> get props => [id, name, level, permissions];
}
