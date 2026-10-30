import 'package:flutter/material.dart';

import '../services/levenshtein_service.dart';
import '../utils/app_theme.dart';
import '../widgets/learning_header.dart';
import '../widgets/pressable_scale.dart';

class ResultScreen extends StatefulWidget {
  final String targetWord;
  final String recognizedWord;
  final int distance;
  final double score;
  final String feedback;

  const ResultScreen({
    super.key,
    required this.targetWord,
    required this.recognizedWord,
    required this.distance,
    required this.score,
    required this.feedback,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  double get scoreValue {
    if (widget.score < 0) return 0;
    if (widget.score > 100) return 100;
    return widget.score;
  }

  double get scoreFraction => scoreValue / 100;

  int get roundedScore => scoreValue.round();

  PronunciationScoreCategory get scoreCategory =>
      LevenshteinService.getCategory(roundedScore);

  Color get scoreColor {
    switch (scoreCategory) {
      case PronunciationScoreCategory.excellent:
        return AppTheme.successGreen;
      case PronunciationScoreCategory.developing:
        return AppTheme.warningOrange;
      case PronunciationScoreCategory.retry:
        return AppTheme.dangerRed;
    }
  }

  IconData get resultIcon {
    switch (scoreCategory) {
      case PronunciationScoreCategory.excellent:
        return Icons.emoji_events_rounded;
      case PronunciationScoreCategory.developing:
        return Icons.star_rounded;
      case PronunciationScoreCategory.retry:
        return Icons.replay_rounded;
    }
  }

  String get resultTitle => LevenshteinService.getTitle(roundedScore);

  String get resultSubtitle => LevenshteinService.getFeedback(roundedScore);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
          child: Column(
            children: [
              LearningHeader(
                title: 'LingoJoy',
                subtitle: 'HASIL LATIHAN',
                showBackButton: true,
                onBack: () {
                  Navigator.pop(context, 'retry');
                },
              ),

              const SizedBox(height: 18),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildHeroResultCard(),

                      const SizedBox(height: 16),

                      _buildProgressCard(),

                      const SizedBox(height: 16),

                      _buildWordResultCard(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              _buildBottomButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroResultCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(38),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(resultIcon, color: scoreColor, size: 54),
          ),

          const SizedBox(height: 14),

          Text(
            resultTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: scoreColor,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            resultSubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.mutedText,
              height: 1.35,
            ),
          ),

          const SizedBox(height: 20),

          _buildScoreCircle(),
        ],
      ),
    );
  }

  Widget _buildScoreCircle() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: scoreFraction),
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: 150,
          height: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 12,
                  backgroundColor: AppTheme.softGray,
                  valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(value * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const Text(
                    'SKOR',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.mutedText,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F0),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white, width: 5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Skor Kemiripan Kata',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppTheme.darkText,
            ),
          ),

          const SizedBox(height: 12),

          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: scoreFraction),
            duration: const Duration(milliseconds: 850),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      color: Colors.white,
                    ),
                    FractionallySizedBox(
                      widthFactor: value,
                      child: Container(
                        height: 16,
                        decoration: BoxDecoration(
                          color: scoreColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          Text(
            widget.feedback,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordResultCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildWordRow(
            label: 'Kata Target',
            value: widget.targetWord.toUpperCase(),
            icon: Icons.flag_rounded,
            color: AppTheme.softBlue,
          ),

          const SizedBox(height: 12),

          _buildWordRow(
            label: 'Suara Kamu',
            value: widget.recognizedWord.isEmpty
                ? '-'
                : widget.recognizedWord.toUpperCase(),
            icon: Icons.record_voice_over_rounded,
            color: AppTheme.softGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildWordRow({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.darkText, size: 20),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.mutedText,
                  ),
                ),

                const SizedBox(height: 2),

                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.darkText,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildSecondaryButton(
            label: 'Coba Lagi',
            icon: Icons.replay_rounded,
            onTap: () {
              Navigator.pop(context, 'retry');
            },
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _buildPrimaryButton(
            label: 'Kata Berikutnya',
            icon: Icons.arrow_forward_rounded,
            onTap: () {
              Navigator.pop(context, 'next');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: AppTheme.gold,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.goldDark.withValues(alpha: 0.35),
              blurRadius: 0,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 6),
            Icon(icon, color: Colors.white, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.softGray, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.045),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.darkText, size: 22),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppTheme.darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
