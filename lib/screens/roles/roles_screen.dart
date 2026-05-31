import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_constants.dart';
import '../../models/phase3_models.dart';
import '../../services/community_service.dart';
import '../../models/user_model.dart';

class RoleService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Create default roles for community
  Future<void> createDefaultRoles(String communityId) async {
    final batch = _db.batch();
    final defaults = [
      {'name': 'Owner',     'color': '#FFD700', 'level': 'owner',     'position': 0, 'permissions': RoleModel.allPermissions},
      {'name': 'Admin',     'color': '#FF6B35', 'level': 'admin',     'position': 1, 'permissions': RoleModel.allPermissions.where((p) => p != 'manage_roles').toList()},
      {'name': 'Moderator', 'color': '#6C63FF', 'level': 'moderator', 'position': 2, 'permissions': ['send_messages','manage_messages','kick_members','pin_messages','create_polls','create_events']},
      {'name': 'Member',    'color': '#9090B0', 'level': 'member',    'position': 3, 'permissions': ['send_messages','create_polls'], 'isDefault': true},
    ];
    for (final r in defaults) {
      final ref = _db.collection('communities').doc(communityId).collection('roles').doc();
      batch.set(ref, {...r, 'communityId': communityId});
    }
    await batch.commit();
  }

  Stream<List<RoleModel>> streamRoles(String communityId) {
    return _db
        .collection('communities')
        .doc(communityId)
        .collection('roles')
        .orderBy('position')
        .snapshots()
        .map((s) => s.docs.map((d) => RoleModel.fromFirestore(d)).toList());
  }

  Future<void> assignRole({
    required String communityId,
    required String userId,
    required RoleLevel level,
  }) async {
    final batch = _db.batch();
    final communityRef = _db.collection('communities').doc(communityId);

    // Remove from all role lists
    batch.update(communityRef, {
      'adminIds': FieldValue.arrayRemove([userId]),
      'moderatorIds': FieldValue.arrayRemove([userId]),
    });

    // Add to correct list
    if (level == RoleLevel.admin) {
      batch.update(communityRef, {'adminIds': FieldValue.arrayUnion([userId])});
    } else if (level == RoleLevel.moderator) {
      batch.update(communityRef, {'moderatorIds': FieldValue.arrayUnion([userId])});
    }

    await batch.commit();
  }

  Future<void> kickMember({required String communityId, required String userId}) async {
    await _db.collection('communities').doc(communityId).update({
      'memberIds': FieldValue.arrayRemove([userId]),
      'adminIds': FieldValue.arrayRemove([userId]),
      'moderatorIds': FieldValue.arrayRemove([userId]),
      'memberCount': FieldValue.increment(-1),
    });
    await _db.collection('users').doc(userId).update({
      'communityIds': FieldValue.arrayRemove([communityId]),
    });
  }

  Future<void> banMember({required String communityId, required String userId}) async {
    await kickMember(communityId: communityId, userId: userId);
    await _db.collection('communities').doc(communityId).update({
      'bannedIds': FieldValue.arrayUnion([userId]),
    });
  }

  Future<RoleLevel> getUserRole(String communityId, String userId) async {
    final doc = await _db.collection('communities').doc(communityId).get();
    final data = doc.data() as Map<String, dynamic>;
    if (data['ownerId'] == userId) return RoleLevel.owner;
    if ((data['adminIds'] as List? ?? []).contains(userId)) return RoleLevel.admin;
    if ((data['moderatorIds'] as List? ?? []).contains(userId)) return RoleLevel.moderator;
    return RoleLevel.member;
  }
}

// ─── Roles Management Screen ──────────────────────────────────

class RolesScreen extends StatelessWidget {
  final String communityId;
  final String currentUserId;
  const RolesScreen({super.key, required this.communityId, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final roleService = RoleService();
    final communityService = CommunityService();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary), onPressed: () => context.pop()),
        title: Text('Roles & Members', style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: StreamBuilder<List<RoleModel>>(
        stream: roleService.streamRoles(communityId),
        builder: (context, roleSnap) {
          final roles = roleSnap.data ?? _defaultRoles();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('ROLES', style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
              const SizedBox(height: 12),
              ...roles.map((role) => _RoleTile(role: role)),
              const SizedBox(height: 24),
              Text('MEMBERS', style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
              const SizedBox(height: 12),
              // Member list with role assignment
              StreamBuilder<Object>(
                stream: Stream.fromFuture(communityService.getCommunity(communityId)),
                builder: (context, snap) {
                  final community = snap.data as dynamic;
                  if (community == null) return const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2));
                  return const Text('Member list loads from community', style: TextStyle(color: AppColors.textMuted));
                },
              ),
            ],
          );
        },
      ),
    );
  }

  List<RoleModel> _defaultRoles() => [
    RoleModel(id: '1', communityId: communityId, name: 'Owner',     color: '#FFD700', level: RoleLevel.owner,     position: 0),
    RoleModel(id: '2', communityId: communityId, name: 'Admin',     color: '#FF6B35', level: RoleLevel.admin,     position: 1),
    RoleModel(id: '3', communityId: communityId, name: 'Moderator', color: '#6C63FF', level: RoleLevel.moderator, position: 2),
    RoleModel(id: '4', communityId: communityId, name: 'Member',    color: '#9090B0', level: RoleLevel.member,    position: 3, isDefault: true),
  ];
}

class _RoleTile extends StatelessWidget {
  final RoleModel role;
  const _RoleTile({required this.role});

  IconData get _icon {
    switch (role.level) {
      case RoleLevel.owner: return Icons.star_rounded;
      case RoleLevel.admin: return Icons.shield_rounded;
      case RoleLevel.moderator: return Icons.gavel_rounded;
      case RoleLevel.member: return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse(role.color.replaceFirst('#', '0xFF')));
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(role.name, style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                    if (role.isDefault) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.bgElevated, borderRadius: BorderRadius.circular(6)),
                        child: Text('Default', style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 10)),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${role.permissions.length} permissions',
                  style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
        ],
      ),
    );
  }
}

// ─── Role badge widget (used in profile/member lists) ─────────

class RoleBadge extends StatelessWidget {
  final RoleLevel role;
  final bool compact;
  const RoleBadge({super.key, required this.role, this.compact = false});

  Color get _color {
    switch (role) {
      case RoleLevel.owner: return const Color(0xFFFFD700);
      case RoleLevel.admin: return const Color(0xFFFF6B35);
      case RoleLevel.moderator: return AppColors.primary;
      case RoleLevel.member: return AppColors.textMuted;
    }
  }

  String get _label {
    switch (role) {
      case RoleLevel.owner: return compact ? '👑' : '👑 Owner';
      case RoleLevel.admin: return compact ? '🛡️' : '🛡️ Admin';
      case RoleLevel.moderator: return compact ? '⚖️' : '⚖️ Mod';
      case RoleLevel.member: return compact ? '👤' : 'Member';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Text(
        _label,
        style: GoogleFonts.dmSans(
          color: _color,
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
