import 'package:flutter/material.dart';

import '../utils/app_theme.dart';
import 'perfect_star_chip.dart';
import 'pressable_scale.dart';

class LearningHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool showBackButton;
  final VoidCallback? onBack;
  final bool showStar;

  const LearningHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.school_rounded,
    this.showBackButton = false,
    this.onBack,
    this.showStar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildLeading(context),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (subtitle != null) ...[
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.mutedText,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
              ],
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.goldDark,
                ),
              ),
            ],
          ),
        ),

        if (showStar) const PerfectStarChip(),
      ],
    );
  }

  Widget _buildLeading(BuildContext context) {
    if (showBackButton) {
      return PressableScale(
        scale: 0.92,
        onTap: onBack ?? () => Navigator.pop(context),
        child: Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: AppTheme.darkText,
            size: 26,
          ),
        ),
      );
    }

    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
        color: AppTheme.softBlue,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppTheme.darkText, size: 24),
    );
  }
}
