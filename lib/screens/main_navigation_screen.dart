import 'package:flutter/material.dart';

import '../utils/app_theme.dart';
import '../widgets/learning_bottom_nav_bar.dart';
import 'games_screen.dart';
import 'profile_screen.dart';
import 'home_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final PageController pageController = PageController();

  int currentIndex = 0;
  int profileRefreshTrigger = 0;

  void changePage(int index) {
    if (index == currentIndex) {
      if (index == 2) {
        setState(() {
          profileRefreshTrigger++;
        });
      }
      return;
    }

    setState(() {
      currentIndex = index;
      if (index == 2) {
        profileRefreshTrigger++;
      }
    });

    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      body: Stack(
        children: [
          Positioned.fill(
            child: PageView(
              controller: pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                HomeScreen(
                  showBottomNav: false,
                  onOpenGames: () {
                    changePage(1);
                  },
                  onOpenProfile: () {
                    changePage(2);
                  },
                ),
                const GamesScreen(),
                ProfileScreen(
                  showBottomNav: false,
                  refreshTrigger: profileRefreshTrigger,
                  onOpenHome: () {
                    changePage(0);
                  },
                  onOpenGames: () {
                    changePage(1);
                  },
                ),
              ],
            ),
          ),

          Positioned(
            left: 18,
            right: 18,
            bottom: 10,
            child: SafeArea(
              top: false,
              child: LearningBottomNavBar(
                currentIndex: currentIndex,
                onChanged: changePage,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
