import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_constants.dart';

class TenkuAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final bool showOnlineIndicator;
  final bool isOnline;
  final VoidCallback? onTap;

  const TenkuAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = AppDimensions.avatarMedium,
    this.showOnlineIndicator = false,
    this.isOnline = false,
    this.onTap,
  });

  Color _getAvatarColor(String name) {
    final colors = [
      AppColors.primary,
      AppColors.accent,
      const Color(0xFFFF6B6B),
      const Color(0xFFFFB020),
      const Color(0xFF00B4D8),
      const Color(0xFF9C92FF),
      const Color(0xFFFF7FAB),
    ];
    final index = name.isNotEmpty ? name.codeUnitAt(0) % colors.length : 0;
    return colors[index];
  }

  @override
  Widget build(BuildContext context) {
    final avatarColor = _getAvatarColor(name);
    final initials = name.isNotEmpty
        ? name.trim().split(' ').take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join()
        : '?';

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: avatarColor.withOpacity(0.2),
              border: Border.all(color: avatarColor.withOpacity(0.3), width: 1.5),
            ),
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Center(
                        child: Text(
                          initials,
                          style: GoogleFonts.dmSans(
                            color: avatarColor,
                            fontSize: size * 0.35,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Center(
                        child: Text(
                          initials,
                          style: GoogleFonts.dmSans(
                            color: avatarColor,
                            fontSize: size * 0.35,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      initials,
                      style: GoogleFonts.dmSans(
                        color: avatarColor,
                        fontSize: size * 0.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
          ),
          if (showOnlineIndicator)
            Positioned(
              bottom: 1,
              right: 1,
              child: Container(
                width: size * 0.28,
                height: size * 0.28,
                decoration: BoxDecoration(
                  color: isOnline ? AppColors.online : AppColors.offline,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.bgDark, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
