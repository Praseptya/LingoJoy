import 'package:flutter/material.dart';

import '../services/perfect_score_notifier.dart';
import '../utils/app_theme.dart';

class PerfectStarChip extends StatefulWidget {
  const PerfectStarChip({super.key});

  @override
  State<PerfectStarChip> createState() => _PerfectStarChipState();
}

class _PerfectStarChipState extends State<PerfectStarChip> {
  @override
  void initState() {
    super.initState();
    PerfectScoreNotifier.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: PerfectScoreNotifier.count,
      builder: (context, perfectCount, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, color: AppTheme.gold, size: 18),
              const SizedBox(width: 6),
              Text(
                '$perfectCount',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.goldDark,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
