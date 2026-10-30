import 'package:flutter/material.dart';

import '../models/practice_result_model.dart';
import '../models/word_model.dart';
import '../services/database_service.dart';
import '../services/word_service.dart';
import '../utils/app_theme.dart';
import '../widgets/learning_bottom_nav_bar.dart';
import '../widgets/perfect_star_chip.dart';
import '../widgets/pressable_scale.dart';
import 'about_screen.dart';
import 'instruction_screen.dart';
import 'practice_screen.dart';
import 'word_list_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool showBottomNav;
  final VoidCallback? onOpenGames;
  final VoidCallback? onOpenProfile;

  const HomeScreen({
    super.key,
    this.showBottomNav = true,
    this.onOpenGames,
    this.onOpenProfile,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WordService wordService = WordService();

  late Future<_HomeDashboardData> dashboardFuture;

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

  @override
  void initState() {
    super.initState();
    dashboardFuture = _loadDashboardData();
  }

  Future<_HomeDashboardData> _loadDashboardData() async {
    final words = await wordService.loadWords();
    final results = await DatabaseService.instance.getAllPracticeResults();

    final categories = words.map((word) => word.category).toSet().toList();
    final practicedWords = results
        .map((item) => '${item.category.toLowerCase()}::${item.word.toLowerCase()}')
        .toSet();

    final totalScore = results.fold<int>(0, (sum, item) => sum + item.score);
    final averageScore = results.isEmpty ? 0 : (totalScore / results.length).round();

    return _HomeDashboardData(
      words: words,
      categories: categories,
      results: results,
      practicedWordCount: practicedWords.length,
      averageScore: averageScore,
    );
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      dashboardFuture = _loadDashboardData();
    });
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  String _categoryLabel(String category) {
    return AppTheme.getCategoryLabel(category);
  }

  List<String> _recommendedCategories(List<String> categories) {
    const priority = ['Angka', 'Hewan', 'Buah'];

    final recommended = <String>[];

    for (final item in priority) {
      if (categories.contains(item)) {
        recommended.add(item);
      }
    }

    for (final item in categories) {
      if (recommended.length >= 3) break;
      if (!recommended.contains(item)) {
        recommended.add(item);
      }
    }

    return recommended;
  }

  void _openCategory(String category) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WordListScreen(category: category)),
    ).then((_) => _refreshDashboard());
  }

  Future<void> _continuePractice(_HomeDashboardData data) async {
    if (data.results.isEmpty) {
      if (data.categories.isNotEmpty) {
        _openCategory(data.categories.first);
      }
      return;
    }

    final lastResult = data.results.first;
    final categoryWords = data.words
        .where((word) => word.category == lastResult.category)
        .toList();

    if (categoryWords.isEmpty) {
      _openCategory(lastResult.category);
      return;
    }

    final index = categoryWords.indexWhere(
      (word) => word.word.toLowerCase() == lastResult.word.toLowerCase(),
    );

    final safeIndex = index >= 0 ? index : 0;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PracticeScreen(
          word: categoryWords[safeIndex],
          words: categoryWords,
          currentIndex: safeIndex,
        ),
      ),
    ).then((_) => _refreshDashboard());
  }

  @override
  Widget build(BuildContext context) {
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
              Expanded(
                child: FutureBuilder<_HomeDashboardData>(
                  future: dashboardFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppTheme.gold),
                      );
                    }

                    final data = snapshot.data ?? _HomeDashboardData.empty();

                    return RefreshIndicator(
                      color: AppTheme.gold,
                      onRefresh: _refreshDashboard,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(
                          bottom: AppTheme.pageBottomNavSpace,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHowToUseCard(),
                            const SizedBox(height: 16),
                            _buildHeroCard(data),
                            const SizedBox(height: 18),
                            _buildProgressSummary(data),
                            const SizedBox(height: 20),
                            _buildContinueCard(data),
                            const SizedBox(height: 22),
                            _buildTodayPractice(data.categories),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),
              if (widget.showBottomNav) ...[
                const SizedBox(height: 10),
                LearningBottomNavBar(
                  currentIndex: 0,
                  onTapHome: () {},
                  onTapGames: () {
                    widget.onOpenGames?.call();
                  },
                  onTapProfile: () {
                    widget.onOpenProfile?.call();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Row(
      children: [
        Expanded(
          child: PressableScale(
            scale: 0.96,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: AppTheme.softBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: AppTheme.darkText,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                const Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'DASHBOARD BELAJAR',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.mutedText,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'LingoJoy',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.goldDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const PerfectStarChip(),
      ],
    );
  }

  Widget _buildHeroCard(_HomeDashboardData data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.softBeige,
        borderRadius: BorderRadius.circular(34),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selamat datang di LingoJoy!',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ayo latihan pengucapan bahasa Inggris dengan ceria hari ini.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: AppTheme.mutedText,
                  ),
                ),
                const SizedBox(height: 18),
                PressableScale(
                  scale: 0.96,
                  onTap: () => _continuePractice(data),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.gold,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.goldDark.withValues(alpha: 0.35),
                          blurRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 21,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          data.results.isEmpty ? 'Mulai Latihan' : 'Lanjutkan',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 78,
            height: 78,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.record_voice_over_rounded,
              color: AppTheme.goldDark,
              size: 38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSummary(_HomeDashboardData data) {
    final totalWords = data.words.length;
    final wordProgress = totalWords == 0
        ? '0/0'
        : '${data.practicedWordCount}/$totalWords';

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Words',
            value: wordProgress,
            icon: Icons.menu_book_rounded,
            color: AppTheme.softBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            title: 'Practice',
            value: '${data.results.length}',
            icon: Icons.school_rounded,
            color: AppTheme.softGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            title: 'Average',
            value: '${data.averageScore}%',
            icon: Icons.bar_chart_rounded,
            color: const Color(0xFFFFF2C1),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.darkText, size: 25),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueCard(_HomeDashboardData data) {
    final hasHistory = data.results.isNotEmpty;
    final lastResult = hasHistory ? data.results.first : null;

    return PressableScale(
      scale: 0.98,
      onTap: () => _continuePractice(data),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppTheme.gold.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasHistory
                    ? Icons.replay_rounded
                    : Icons.rocket_launch_rounded,
                color: AppTheme.goldDark,
                size: 30,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasHistory ? 'Lanjutkan Latihan' : 'Latihan Pertama',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    hasHistory
                        ? '${_capitalize(lastResult!.word)} • ${_categoryLabel(lastResult.category)} • Skor ${lastResult.score}%'
                        : 'Pilih kata pertama dan mulai berlatih.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.mutedText,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.mutedText),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayPractice(List<String> categories) {
    final recommended = _recommendedCategories(categories);

    if (recommended.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Latihan Hari Ini',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.darkText,
                ),
              ),
            ),
            PressableScale(
              scale: 0.95,
              onTap: () {
                widget.onOpenGames?.call();
              },
              child: const Text(
                'LIHAT SEMUA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.goldDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          children: recommended.map((category) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildMiniCategoryCard(category),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMiniCategoryCard(String category) {
    return PressableScale(
      scale: 0.98,
      onTap: () => _openCategory(category),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.getCategoryCardColor(category),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: AppTheme.getCategoryBorderColor(category),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(
                  previewImages[category] ?? '',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      AppTheme.getCategoryIcon(category),
                      color: AppTheme.darkText,
                      size: 28,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _categoryLabel(category),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Latih 10 kata pilihan',
                    style: TextStyle(fontSize: 12, color: AppTheme.mutedText),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.darkText),
          ],
        ),
      ),
    );
  }

  Widget _buildHowToUseCard() {
    return PressableScale(
      scale: 0.98,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const InstructionScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.softBlue,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppTheme.softBlue.withValues(alpha: 0.35),
              blurRadius: 0,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_circle_fill_rounded,
                color: AppTheme.goldDark,
                size: 40,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How to Use',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.darkText,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tap di sini untuk melihat cara memakai aplikasi.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppTheme.darkText,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

}

class _HomeDashboardData {
  final List<WordModel> words;
  final List<String> categories;
  final List<PracticeResult> results;
  final int practicedWordCount;
  final int averageScore;

  const _HomeDashboardData({
    required this.words,
    required this.categories,
    required this.results,
    required this.practicedWordCount,
    required this.averageScore,
  });

  factory _HomeDashboardData.empty() {
    return const _HomeDashboardData(
      words: [],
      categories: [],
      results: [],
      practicedWordCount: 0,
      averageScore: 0,
    );
  }
}
