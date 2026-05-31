import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_constants.dart';
import '../../models/message_model.dart';
import '../../services/file_share_service.dart';

class FileMessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const FileMessageBubble({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    switch (message.type) {
      case MessageType.image:
        return _ImageBubble(message: message, isMe: isMe);
      case MessageType.video:
        return _VideoBubble(message: message, isMe: isMe);
      case MessageType.audio:
        return _AudioBubble(message: message, isMe: isMe);
      case MessageType.file:
        return _FileBubble(message: message, isMe: isMe);
      default:
        return const SizedBox();
    }
  }
}

class _ImageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  const _ImageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (message.mediaUrl != null) {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => _FullScreenImage(url: message.mediaUrl!),
          ));
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: message.mediaUrl ?? '',
          width: 220,
          height: 220,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            width: 220,
            height: 220,
            color: AppColors.bgElevated,
            child: const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
          ),
          errorWidget: (_, __, ___) => Container(
            width: 220,
            height: 80,
            color: AppColors.bgElevated,
            child: const Center(child: Icon(Icons.broken_image_rounded, color: AppColors.textMuted)),
          ),
        ),
      ),
    );
  }
}

class _VideoBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  const _VideoBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (message.mediaUrl != null) {
          final uri = Uri.parse(message.mediaUrl!);
          if (await canLaunchUrl(uri)) await launchUrl(uri);
        }
      },
      child: Container(
        width: 220,
        height: 140,
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.movie_rounded, color: AppColors.textMuted, size: 48),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.9),
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Text(
                message.fileName ?? 'Video',
                style: GoogleFonts.dmSans(color: Colors.white, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  const _AudioBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe ? AppColors.myBubble : AppColors.theirBubble,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              if (message.mediaUrl != null) {
                final uri = Uri.parse(message.mediaUrl!);
                if (await canLaunchUrl(uri)) await launchUrl(uri);
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.2),
                border: Border.all(color: AppColors.primary.withOpacity(0.5)),
              ),
              child: const Icon(Icons.play_arrow_rounded, color: AppColors.primary, size: 22),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.fileName ?? 'Audio',
                  style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  message.fileSize != null ? FileShareService.formatFileSize(message.fileSize!) : '',
                  style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FileBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  const _FileBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final fileIcon = _getFileIcon(message.fileName);
    final fileColor = _getFileColor(message.fileName);

    return GestureDetector(
      onTap: () async {
        if (message.mediaUrl != null) {
          final uri = Uri.parse(message.mediaUrl!);
          if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? AppColors.myBubble : AppColors.theirBubble,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: fileColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: fileColor.withOpacity(0.3)),
              ),
              child: Icon(fileIcon, color: fileColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.fileName ?? 'File',
                    style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (message.fileSize != null)
                        Text(
                          FileShareService.formatFileSize(message.fileSize!),
                          style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 11),
                        ),
                      const Spacer(),
                      const Icon(Icons.download_rounded, color: AppColors.primary, size: 16),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String? fileName) {
    if (fileName == null) return Icons.insert_drive_file_rounded;
    final ext = fileName.split('.').last.toLowerCase();
    const m = {
      'pdf': Icons.picture_as_pdf_rounded,
      'doc': Icons.description_rounded, 'docx': Icons.description_rounded,
      'xls': Icons.table_chart_rounded, 'xlsx': Icons.table_chart_rounded,
      'zip': Icons.folder_zip_rounded, 'rar': Icons.folder_zip_rounded,
    };
    return m[ext] ?? Icons.insert_drive_file_rounded;
  }

  Color _getFileColor(String? fileName) {
    if (fileName == null) return AppColors.textMuted;
    final ext = fileName.split('.').last.toLowerCase();
    const m = {
      'pdf': Color(0xFFFF4466),
      'doc': Color(0xFF2B6CE6), 'docx': Color(0xFF2B6CE6),
      'xls': Color(0xFF00A550), 'xlsx': Color(0xFF00A550),
      'zip': Color(0xFFFFB020), 'rar': Color(0xFFFFB020),
    };
    return m[ext] ?? AppColors.primary;
  }
}

class _FullScreenImage extends StatelessWidget {
  final String url;
  const _FullScreenImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
