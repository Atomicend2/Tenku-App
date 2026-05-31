import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/status_service.dart';
import '../../models/status_model.dart';
import '../../widgets/common/tenku_avatar.dart';

class StatusScreen extends StatelessWidget {
  const StatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) return const SizedBox();
    final statusService = StatusService();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        titleSpacing: 20,
        title: Text('Status', style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/create-status'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: StreamBuilder<List<StatusModel>>(
        stream: statusService.streamStatuses(user.uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2));
          }
          final statuses = snap.data ?? [];
          final groups = statusService.groupStatusesByUser(statuses, user.uid);

          if (groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.circle_outlined, color: AppColors.textMuted, size: 64),
                  const SizedBox(height: 16),
                  Text('No status updates', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('Post your first status!', style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 14)),
                ],
              ),
            );
          }

          final myGroup = groups.where((g) => g.userId == user.uid).toList();
          final otherGroups = groups.where((g) => g.userId != user.uid).toList();

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              // My status
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text('MY STATUS', style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
              ),
              if (myGroup.isEmpty)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Stack(
                    children: [
                      TenkuAvatar(imageUrl: user.avatarUrl, name: user.displayName, size: 52),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.bgDark, width: 2),
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 12),
                        ),
                      ),
                    ],
                  ),
                  title: Text('Add to my status', style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                  subtitle: Text('Tap to add a status update', style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 13)),
                  onTap: () => context.push('/create-status'),
                )
              else
                _StatusGroupTile(group: myGroup.first, currentUserId: user.uid, statusService: statusService, isMe: true),

              if (otherGroups.isNotEmpty) ...[
                const Divider(color: AppColors.divider, indent: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text('RECENT UPDATES', style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                ),
                ...otherGroups.map((group) => _StatusGroupTile(
                  group: group,
                  currentUserId: user.uid,
                  statusService: statusService,
                  isMe: false,
                )),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _StatusGroupTile extends StatelessWidget {
  final UserStatusGroup group;
  final String currentUserId;
  final StatusService statusService;
  final bool isMe;

  const _StatusGroupTile({
    required this.group,
    required this.currentUserId,
    required this.statusService,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final latestStatus = group.statuses.isNotEmpty ? group.statuses.first : null;
    final timeStr = latestStatus != null ? _formatTime(latestStatus.createdAt) : '';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: group.isViewed
              ? null
              : const LinearGradient(colors: [AppColors.primary, AppColors.accent]),
          border: group.isViewed ? Border.all(color: AppColors.textMuted, width: 2) : null,
        ),
        padding: const EdgeInsets.all(2),
        child: TenkuAvatar(imageUrl: group.userAvatar, name: group.userName, size: 48),
      ),
      title: Text(
        isMe ? 'My Status' : group.userName,
        style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        latestStatus?.text ?? timeStr,
        style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 13),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(timeStr, style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 11)),
      onTap: () => _viewStatus(context),
    );
  }

  void _viewStatus(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _StatusViewScreen(group: group, currentUserId: currentUserId, statusService: statusService),
    ));
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('HH:mm').format(dt);
  }
}

class _StatusViewScreen extends StatefulWidget {
  final UserStatusGroup group;
  final String currentUserId;
  final StatusService statusService;

  const _StatusViewScreen({required this.group, required this.currentUserId, required this.statusService});

  @override
  State<_StatusViewScreen> createState() => _StatusViewScreenState();
}

class _StatusViewScreenState extends State<_StatusViewScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _progressCtrl;

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 5));
    _progressCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) _next();
    });
    _progressCtrl.forward();
    _markViewed();
  }

  void _markViewed() {
    final status = widget.group.statuses[_currentIndex];
    widget.statusService.markAsViewed(statusId: status.id, viewerId: widget.currentUserId);
  }

  void _next() {
    if (_currentIndex < widget.group.statuses.length - 1) {
      setState(() => _currentIndex++);
      _progressCtrl.reset();
      _progressCtrl.forward();
      _markViewed();
    } else {
      Navigator.pop(context);
    }
  }

  void _prev() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _progressCtrl.reset();
      _progressCtrl.forward();
    }
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.group.statuses[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          final width = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < width / 2) _prev();
          else _next();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Content
            if (status.type == StatusType.text)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(int.parse((status.backgroundColor ?? '#6C63FF').replaceFirst('#', '0xFF'))),
                      AppColors.bgDark,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      status.text ?? '',
                      style: GoogleFonts.dmSans(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
            else
              Container(color: Colors.black),

            // Progress bars
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    children: List.generate(widget.group.statuses.length, (i) {
                      return Expanded(
                        child: Container(
                          height: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: AppColors.divider,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: i < _currentIndex
                              ? Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)))
                              : i == _currentIndex
                                  ? AnimatedBuilder(
                                      animation: _progressCtrl,
                                      builder: (_, __) => FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: _progressCtrl.value,
                                        child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))),
                                      ),
                                    )
                                  : const SizedBox(),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),

            // User info
            Positioned(
              top: 40,
              left: 16,
              right: 16,
              child: SafeArea(
                child: Row(
                  children: [
                    TenkuAvatar(imageUrl: widget.group.userAvatar, name: widget.group.userName, size: 36),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.group.userName, style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                        Text(_formatTime(status.createdAt), style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('HH:mm').format(dt);
  }
}
