import 'package:flutter/material.dart';

import '../models/practice_result_model.dart';
import '../services/database_service.dart';
import '../services/perfect_score_notifier.dart';
import '../utils/app_theme.dart';
import '../widgets/learning_header.dart';
import '../widgets/learning_bottom_nav_bar.dart';
import '../widgets/learning_state_widget.dart';
import '../widgets/pressable_scale.dart';

class ProfileScreen extends StatefulWidget {
  final bool showBottomNav;
  final VoidCallback? onOpenHome;
  final VoidCallback? onOpenGames;
  final int refreshTrigger;

  const ProfileScreen({
    super.key,
    this.showBottomNav = true,
    this.onOpenHome,
    this.onOpenGames,
    this.refreshTrigger = 0,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const int targetWordCount = 80;

  late Future<List<PracticeResult>> futureResults;

  @override
  void initState() {
    super.initState();
    loadResults();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.refreshTrigger != widget.refreshTrigger) {
      setState(() {
        loadResults();
      });
    }
  }

  void loadResults() {
    futureResults = DatabaseService.instance.getAllPracticeResults();
  }

  String formatDate(String value) {
    final date = DateTime.tryParse(value);

    if (date == null) {
      return value;
    }

    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  int getAverageScore(List<PracticeResult> results) {
    if (results.isEmpty) return 0;

    final total = results.fold<int>(0, (sum, item) => sum + item.score);

    return (total / results.length).round();
  }

  int getPracticedWordCount(List<PracticeResult> results) {
    final practicedWords = results
        .map((item) => '${item.category.toLowerCase()}::${item.word.toLowerCase()}')
        .toSet();

    return practicedWords.length;
  }

  Color getScoreColor(int score) {
    if (score >= 90) {
      return const Color(0xFF55D36A);
    }

    if (score >= 50) {
      return const Color(0xFFFFB74D);
    }

    return Colors.redAccent;
  }

  String capitalize(String text) {
    if (text.isEmpty) return text;

    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  Future<void> deleteAllHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Hapus Riwayat?',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppTheme.darkText,
            ),
          ),
          content: const Text(
            'Semua data latihan yang tersimpan akan dihapus.',
            style: TextStyle(color: AppTheme.mutedText),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                'Hapus',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await DatabaseService.instance.deleteAllPracticeResults();
      await PerfectScoreNotifier.refresh();

      if (!mounted) return;

      setState(() {
        loadResults();
      });
    }
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
                child: FutureBuilder<List<PracticeResult>>(
                  future: futureResults,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppTheme.gold),
                      );
                    }

                    final results = snapshot.data ?? [];
                    final averageScore = getAverageScore(results);
                    final practicedWordCount = getPracticedWordCount(results);

                    return SingleChildScrollView(
                      padding: const EdgeInsets.only(
                        bottom: AppTheme.pageBottomNavSpace,
                      ),
                      child: Column(
                        children: [
                          _buildProfileCard(
                            totalPractice: results.length,
                            averageScore: averageScore,
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  title: 'Practice',
                                  value: '${results.length}',
                                  icon: Icons.school_rounded,
                                  color: AppTheme.softBlue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  title: 'Average',
                                  value: '$averageScore%',
                                  icon: Icons.bar_chart_rounded,
                                  color: AppTheme.softGreen,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  title: 'Words',
                                  value: '$practicedWordCount/$targetWordCount',
                                  icon: Icons.menu_book_rounded,
                                  color: const Color(0xFFFFF2C1),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          _buildHistoryHeader(results.isNotEmpty),
                          const SizedBox(height: 12),
                          if (results.isEmpty)
                            _buildEmptyState()
                          else
                            Column(
                              children: results.take(10).map((item) {
                                return _buildHistoryItem(item);
                              }).toList(),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),
              if (widget.showBottomNav) ...[
                const SizedBox(height: 10),
                LearningBottomNavBar(
                  currentIndex: 2,
                  onTapHome: () {
                    widget.onOpenHome?.call();
                  },
                  onTapGames: () {
                    widget.onOpenGames?.call();
                  },
                  onTapProfile: () {},
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return const LearningHeader(title: 'Profile', icon: Icons.person_rounded);
  }

  Widget _buildProfileCard({
    required int totalPractice,
    required int averageScore,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34),
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
            width: 82,
            height: 82,
            decoration: const BoxDecoration(
              color: AppTheme.gold,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Colors.white,
              size: 46,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Young Explorer',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  totalPractice == 0
                      ? 'Start your first practice!'
                      : 'You have completed $totalPractice practices.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.mutedText,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: (averageScore / 100).clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: AppTheme.softGray,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.gold,
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

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.darkText, size: 26),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryHeader(bool hasData) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Recent Practice',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.darkText,
            ),
          ),
        ),
        if (hasData)
          PressableScale(
            scale: 0.95,
            onTap: deleteAllHistory,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFECEC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                    size: 16,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Reset',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const LearningEmptyState(
      icon: Icons.history_rounded,
      title: 'Belum Ada Latihan',
      message:
          'Mulai latihan terlebih dahulu untuk melihat hasil belajarmu di sini.',
    );
  }

  Widget _buildHistoryItem(PracticeResult item) {
    final scoreColor = getScoreColor(item.score);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${item.score}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: scoreColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        capitalize(item.word),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.darkText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.asrMethod,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: scoreColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Hasil: ${item.recognizedWord} • ${item.feedback}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.mutedText,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.category} • ${formatDate(item.createdAt)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.mutedText,
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
