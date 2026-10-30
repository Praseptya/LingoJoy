import 'package:flutter/material.dart';
import 'pressable_scale.dart';
import '../utils/app_theme.dart';

class HomeCategoryCard extends StatelessWidget {
  final String title;
  final String? imagePath;
  final IconData fallbackIcon;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback onTap;

  const HomeCategoryCard({
    super.key,
    required this.title,
    this.imagePath,
    required this.fallbackIcon,
    required this.backgroundColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: borderColor.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: imagePath != null
                    ? Image.asset(
                        imagePath!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) {
                          return Icon(
                            fallbackIcon,
                            size: 42,
                            color: AppTheme.darkText,
                          );
                        },
                      )
                    : Icon(fallbackIcon, size: 42, color: AppTheme.darkText),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
