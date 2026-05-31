import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_constants.dart';

enum ButtonVariant { primary, secondary, danger, ghost }

class TenkuButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonVariant variant;
  final IconData? icon;
  final double? width;
  final double height;

  const TenkuButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.width,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;

    Color bgColor;
    Color textColor;
    Border? border;

    switch (variant) {
      case ButtonVariant.primary:
        bgColor = isDisabled ? AppColors.primary.withOpacity(0.4) : AppColors.primary;
        textColor = Colors.white;
        border = null;
        break;
      case ButtonVariant.secondary:
        bgColor = AppColors.bgElevated;
        textColor = AppColors.textPrimary;
        border = Border.all(color: AppColors.divider, width: 1);
        break;
      case ButtonVariant.danger:
        bgColor = isDisabled ? AppColors.error.withOpacity(0.4) : AppColors.error;
        textColor = Colors.white;
        border = null;
        break;
      case ButtonVariant.ghost:
        bgColor = Colors.transparent;
        textColor = AppColors.primary;
        border = null;
        break;
    }

    return GestureDetector(
      onTap: isDisabled ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: border,
          boxShadow: variant == ButtonVariant.primary && !isDisabled
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: textColor, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: GoogleFonts.dmSans(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
