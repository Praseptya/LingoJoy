import 'package:flutter/material.dart';

import '../services/word_service.dart';
import '../utils/app_theme.dart';
import '../utils/app_route.dart';
import '../widgets/learning_header.dart';
import '../widgets/home_category_card.dart';
import '../widgets/learning_state_widget.dart';
import 'word_list_screen.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen>
    with AutomaticKeepAliveClientMixin {
  final WordService wordService = WordService();

  final Map<String, String> previewImages = {
    'Angka': 'assets/images/words/one.png',
    'Hewan': 'assets/images/words/cat.png',
    'Buah': 'assets/images/words/apple.png',
    'Benda': 'assets/images/words/book.png',
    'Warna': 'assets/images/words/red.png',
    'Tubuh': 'assets/images/words/head.png',
    'Makanan': 'assets/images/words/rice.png',
    'Transportasi': 'assets/images/words/car.png',
  };

  final Map<String, IconData> previewIcons = {
    'Angka': Icons.looks_one_rounded,
    'Hewan': Icons.pets_rounded,
    'Buah': Icons.apple_rounded,
    'Benda': Icons.menu_book_rounded,
    'Warna': Icons.palette_rounded,
    'Tubuh': Icons.face_rounded,
    'Makanan': Icons.restaurant_rounded,
    'Transportasi': Icons.directions_car_rounded,
  };

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.pageHorizontalPadding,
            AppTheme.pageTopPadding,
            AppTheme.pageHorizontalPadding,
            0,
          ),
          child: Column(
            children: [
              _buildTopHeader(),
              const SizedBox(height: 18),
              _buildHeroCard(),
              const SizedBox(height: 18),
              Expanded(
                child: FutureBuilder<List<String>>(
                  future: wordService.loadCategories(),
                  builder: (context, snapshot) {
                    final categories = snapshot.data ?? [];

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const LearningLoading(message: 'Loading games...');
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.only(
                        bottom: AppTheme.pageBottomNavSpace,
                      ),
                      itemCount: categories.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.92,
                          ),
                      itemBuilder: (context, index) {
                        final category = categories[index];

                        return HomeCategoryCard(
                          title: AppTheme.getCategoryLabel(category),
                          imagePath: previewImages[category],
                          fallbackIcon:
                              previewIcons[category] ?? Icons.category_rounded,
                          backgroundColor: AppTheme.getCategoryCardColor(
                            category,
                          ),
                          borderColor: AppTheme.getCategoryBorderColor(
                            category,
                          ),
                          onTap: () {
                            smoothPush(
                              context,
                              WordListScreen(category: category),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return const LearningHeader(
      title: 'Games',
      icon: Icons.sports_esports_rounded,
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.softBeige,
        borderRadius: BorderRadius.circular(32),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: AppTheme.gold,
            child: Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose a Category',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.darkText,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Pick a word and start speaking!',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
