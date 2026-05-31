import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/community_model.dart';
import '../models/message_model.dart';

class SearchResult {
  final SearchResultType type;
  final String id;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final dynamic data;

  const SearchResult({
    required this.type,
    required this.id,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.data,
  });
}

enum SearchResultType { user, community, message }

class SearchService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Search users by username or display name
  Future<List<UserModel>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    final q = query.toLowerCase().trim();

    // Search by username prefix
    final byUsername = await _db
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: q)
        .where('username', isLessThanOrEqualTo: '$q\uf8ff')
        .limit(10)
        .get();

    // Search by displayName prefix
    final byName = await _db
        .collection('users')
        .where('displayName', isGreaterThanOrEqualTo: query)
        .where('displayName', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(10)
        .get();

    final seen = <String>{};
    final results = <UserModel>[];

    for (final doc in [...byUsername.docs, ...byName.docs]) {
      if (!seen.contains(doc.id)) {
        seen.add(doc.id);
        results.add(UserModel.fromFirestore(doc));
      }
    }

    return results;
  }

  // Search public communities
  Future<List<CommunityModel>> searchCommunities(String query) async {
    if (query.trim().isEmpty) return [];

    final snap = await _db
        .collection('communities')
        .where('isPublic', isEqualTo: true)
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(15)
        .get();

    return snap.docs.map((d) => CommunityModel.fromFirestore(d)).toList();
  }

  // Search messages in a chat
  Future<List<MessageModel>> searchMessages({
    required String chatId,
    required String query,
    bool isChannel = false,
  }) async {
    if (query.trim().isEmpty) return [];

    final collection = isChannel
        ? _db.collection('channels').doc(chatId).collection('messages')
        : _db.collection('chats').doc(chatId).collection('messages');

    // Firestore doesn't natively support full-text, so we fetch recent and filter
    final snap = await collection
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(200)
        .get();

    return snap.docs
        .map((d) => MessageModel.fromFirestore(d))
        .where((m) => m.content.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Combined global search
  Future<List<SearchResult>> globalSearch(String query) async {
    if (query.trim().isEmpty) return [];

    final futures = await Future.wait([
      searchUsers(query),
      searchCommunities(query),
    ]);

    final users = futures[0] as List<UserModel>;
    final communities = futures[1] as List<CommunityModel>;

    final results = <SearchResult>[];

    for (final u in users) {
      results.add(SearchResult(
        type: SearchResultType.user,
        id: u.uid,
        title: u.displayName,
        subtitle: '@${u.username}',
        imageUrl: u.avatarUrl,
        data: u,
      ));
    }

    for (final c in communities) {
      results.add(SearchResult(
        type: SearchResultType.community,
        id: c.id,
        title: c.name,
        subtitle: '${c.memberCount} members',
        imageUrl: c.iconUrl,
        data: c,
      ));
    }

    return results;
  }
}
