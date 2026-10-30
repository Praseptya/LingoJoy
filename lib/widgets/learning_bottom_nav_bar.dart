import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

class LearningBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onChanged;

  final VoidCallback? onTapHome;
  final VoidCallback? onTapGames;
  final VoidCallback? onTapProfile;

  const LearningBottomNavBar({
    super.key,
    required this.currentIndex,
    this.onChanged,
    this.onTapHome,
    this.onTapGames,
    this.onTapProfile,
  });

  void _handleTap(int index) {
    if (index == currentIndex) return;

    if (onChanged != null) {
      onChanged!(index);
      return;
    }

    if (index == 0) {
      onTapHome?.call();
    } else if (index == 1) {
      onTapGames?.call();
    } else if (index == 2) {
      onTapProfile?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / 3;
          const activeWidth = 108.0;
          const activeHeight = 46.0;

          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                left:
                    (itemWidth * currentIndex) +
                    ((itemWidth - activeWidth) / 2),
                top: 4,
                child: Container(
                  width: activeWidth,
                  height: activeHeight,
                  decoration: BoxDecoration(
                    color: AppTheme.gold,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.goldDark.withValues(alpha: 0.35),
                        blurRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  _buildItem(index: 0, icon: Icons.home_rounded, label: 'HOME'),
                  _buildItem(
                    index: 1,
                    icon: Icons.sports_esports_rounded,
                    label: 'GAMES',
                  ),
                  _buildItem(
                    index: 2,
                    icon: Icons.person_outline_rounded,
                    label: 'PROFILE',
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final active = index == currentIndex;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _handleTap(index);
        },
        child: SizedBox(
          height: 56,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: Icon(
                    icon,
                    color: active ? Colors.white : AppTheme.mutedText,
                    size: active ? 20 : 22,
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: active
                      ? Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
