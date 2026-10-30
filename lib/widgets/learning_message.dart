import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

enum LearningMessageType { info, success, warning, error }

Color _messageColor(LearningMessageType type) {
  switch (type) {
    case LearningMessageType.success:
      return AppTheme.successGreen;
    case LearningMessageType.warning:
      return AppTheme.warningOrange;
    case LearningMessageType.error:
      return AppTheme.dangerRed;
    case LearningMessageType.info:
      return AppTheme.gold;
  }
}

IconData _messageIcon(LearningMessageType type) {
  switch (type) {
    case LearningMessageType.success:
      return Icons.check_circle_rounded;
    case LearningMessageType.warning:
      return Icons.info_rounded;
    case LearningMessageType.error:
      return Icons.wifi_off_rounded;
    case LearningMessageType.info:
      return Icons.lightbulb_rounded;
  }
}

void showLearningSnackBar({
  required BuildContext context,
  required String message,
  LearningMessageType type = LearningMessageType.info,
  Duration duration = const Duration(seconds: 3),
  double bottomMargin = 18,
}) {
  final color = _messageColor(type);
  final icon = _messageIcon(type);

  ScaffoldMessenger.of(context).hideCurrentSnackBar();

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      duration: duration,
      margin: EdgeInsets.fromLTRB(18, 0, 18, bottomMargin),
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppTheme.darkText,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> showLearningDialog({
  required BuildContext context,
  required String title,
  required String message,
  LearningMessageType type = LearningMessageType.info,
  String buttonText = 'Mengerti',
}) {
  final color = _messageColor(type);
  final icon = _messageIcon(type);

  return showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 26),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
          decoration: BoxDecoration(
            color: AppTheme.creamBackground,
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: Colors.white, width: 5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 42),
              ),

              const SizedBox(height: 16),

              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.darkText,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.mutedText,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 22),

              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppTheme.gold,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.goldDark.withValues(alpha: 0.35),
                        blurRadius: 0,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      buttonText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
