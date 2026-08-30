import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class ClinicalCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const ClinicalCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.backgroundColor,
    this.borderColor,
    this.width,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor ?? theme.colorScheme.outline.withOpacity(0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F2438).withOpacity(theme.brightness == Brightness.dark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: card,
      );
    }
    return card;
  }
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color backgroundColor;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    required this.backgroundColor,
    this.icon,
  });

  factory StatusBadge.success({required String label, IconData? icon, bool isDark = false}) {
    return StatusBadge(
      label: label,
      color: isDark ? const Color(0xFF34D399) : AppColors.success,
      backgroundColor: isDark ? const Color(0xFF064E3B) : AppColors.successLight,
      icon: icon ?? Icons.check_circle_outline,
    );
  }

  factory StatusBadge.warning({required String label, IconData? icon, bool isDark = false}) {
    return StatusBadge(
      label: label,
      color: isDark ? const Color(0xFFFBBF24) : AppColors.warning,
      backgroundColor: isDark ? const Color(0xFF78350F) : AppColors.warningLight,
      icon: icon ?? Icons.warning_amber_rounded,
    );
  }

  factory StatusBadge.error({required String label, IconData? icon, bool isDark = false}) {
    return StatusBadge(
      label: label,
      color: isDark ? const Color(0xFFF87171) : AppColors.error,
      backgroundColor: isDark ? const Color(0xFF7F1D1D) : AppColors.errorLight,
      icon: icon ?? Icons.error_outline,
    );
  }

  factory StatusBadge.info({required String label, IconData? icon, bool isDark = false}) {
    return StatusBadge(
      label: label,
      color: isDark ? const Color(0xFF38BDF8) : AppColors.info,
      backgroundColor: isDark ? const Color(0xFF0C4A6E) : AppColors.infoLight,
      icon: icon ?? Icons.info_outline,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
