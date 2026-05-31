import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) return const SizedBox();
    final notifService = NotificationService();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
          onPressed: () => context.pop(),
        ),
        title: Text('Notifications', style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: () => notifService.markAllAsRead(user.uid),
            child: Text('Mark all read', style: GoogleFonts.dmSans(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: notifService.streamNotifications(user.uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2));
          }
          final notifications = snap.data ?? [];
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notifications_none_rounded, color: AppColors.textMuted, size: 64),
                  const SizedBox(height: 16),
                  Text('No notifications', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text("You're all caught up!", style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 14)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const Divider(color: AppColors.divider, height: 1, indent: 72),
            itemBuilder: (_, i) {
              final n = notifications[i];
              return _NotificationTile(
                notification: n,
                onTap: () {
                  notifService.markAsRead(n.id);
                  if (n.actionRoute != null) context.push(n.actionRoute!);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  IconData get _icon {
    switch (notification.type) {
      case NotificationType.newMessage: return Icons.chat_bubble_rounded;
      case NotificationType.reply: return Icons.reply_rounded;
      case NotificationType.reaction: return Icons.favorite_rounded;
      case NotificationType.friendRequest: return Icons.person_add_rounded;
      case NotificationType.friendAccepted: return Icons.handshake_rounded;
      case NotificationType.communityInvite: return Icons.group_add_rounded;
      case NotificationType.communityJoin: return Icons.public_rounded;
      case NotificationType.mention: return Icons.alternate_email_rounded;
    }
  }

  Color get _iconColor {
    switch (notification.type) {
      case NotificationType.reaction: return AppColors.error;
      case NotificationType.mention: return AppColors.accent;
      case NotificationType.friendAccepted: return AppColors.success;
      default: return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: notification.isRead ? Colors.transparent : AppColors.primary.withOpacity(0.05),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _iconColor.withOpacity(0.15),
                border: Border.all(color: _iconColor.withOpacity(0.3)),
              ),
              child: Icon(_icon, color: _iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification.title,
                      style: GoogleFonts.dmSans(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
                      )),
                  const SizedBox(height: 3),
                  Text(notification.body,
                      style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(timeago.format(notification.createdAt, locale: 'en'),
                      style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6, left: 8),
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
              ),
          ],
        ),
      ),
    );
  }
}
