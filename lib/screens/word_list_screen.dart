import 'package:flutter/material.dart';

import '../models/word_model.dart';
import '../services/word_service.dart';
import '../utils/app_theme.dart';
import '../widgets/learning_header.dart';
import '../widgets/learning_state_widget.dart';
import '../widgets/pressable_scale.dart';
import 'practice_screen.dart';

class WordListScreen extends StatefulWidget {
  final String category;

  const WordListScreen({super.key, required this.category});

  @override
  State<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> {
  final WordService wordService = WordService();

  late Future<List<WordModel>> futureWords;

  @override
  void initState() {
    super.initState();
    futureWords = wordService.loadWordsByCategory(widget.category);
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final String categoryLabel = AppTheme.getCategoryLabel(widget.category);

    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
          child: Column(
            children: [
              _buildTopHeader(categoryLabel),
              const SizedBox(height: 18),
              _buildCategoryBanner(categoryLabel),
              const SizedBox(height: 18),
              Expanded(
                child: FutureBuilder<List<WordModel>>(
                  future: futureWords,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const LearningLoading(message: 'Loading words...');
                    }
                    if (snapshot.hasError) {
                      return LearningErrorState(
                        title: 'Gagal Memuat Kata',
                        message:
                            'Data kata belum bisa dibuka. Periksa file JSON atau asset aplikasi.',
                        onRetry: () {
                          setState(() {
                            futureWords = wordService.loadWordsByCategory(
                              widget.category,
                            );
                          });
                        },
                      );
                    }

                    final words = snapshot.data ?? [];

                    if (words.isEmpty) {
                      return const LearningEmptyState(
                        icon: Icons.category_rounded,
                        title: 'Belum Ada Kata',
                        message: 'Kategori ini belum memiliki kata latihan.',
                      );
                    }

                    return GridView.builder(
                      itemCount: words.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.82,
                          ),
                      itemBuilder: (context, index) {
                        final word = words[index];

                        return _buildWordCard(word, words, index);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(String categoryLabel) {
    return LearningHeader(
      title: categoryLabel,
      showBackButton: true,
      onBack: () {
        Navigator.pop(context);
      },
    );
  }

  Widget _buildCategoryBanner(String categoryLabel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getCategoryCardColor(widget.category),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppTheme.getCategoryBorderColor(widget.category),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(
              AppTheme.getCategoryIcon(widget.category),
              color: AppTheme.goldDark,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$categoryLabel Vocabulary',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Choose a word and start speaking!',
                  style: TextStyle(fontSize: 14, color: AppTheme.mutedText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordCard(WordModel word, List<WordModel> words, int index) {
    final borderRadius = BorderRadius.circular(28);

    return PressableScale(
      scale: 0.97,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PracticeScreen(word: word, words: words, currentIndex: index),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius,
          border: Border.all(
            color: AppTheme.getCategoryBorderColor(widget.category),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.getCategoryBorderColor(
                widget.category,
              ).withValues(alpha: 0.28),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.getCategoryCardColor(widget.category),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Image.asset(
                  'assets/images/words/${word.imageName}',
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) {
                    return Icon(
                      AppTheme.getCategoryIcon(widget.category),
                      size: 54,
                      color: AppTheme.goldDark,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _capitalize(word.word),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tap to play',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
