import 'package:flutter/material.dart';

import '../utils/app_theme.dart';
import '../widgets/learning_header.dart';

class InstructionScreen extends StatelessWidget {
  const InstructionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
          child: Column(
            children: [
              _buildTopHeader(context),
              const SizedBox(height: 20),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildHeroCard(),
                      const SizedBox(height: 20),

                      _buildStepCard(
                        number: '1',
                        title: 'Choose Vocabulary',
                        description:
                            'Pilih kategori kata yang ingin kamu pelajari.',
                        icon: Icons.category_rounded,
                        color: AppTheme.softBlue,
                      ),

                      _buildStepCard(
                        number: '2',
                        title: 'Listen First',
                        description:
                            'Tekan tombol Listen untuk mendengar contoh pengucapan.',
                        icon: Icons.volume_up_rounded,
                        color: const Color(0xFFFFF2C1),
                      ),

                      _buildStepCard(
                        number: '3',
                        title: 'Speak Clearly',
                        description:
                            'Tekan tombol mikrofon lalu ucapkan kata dengan jelas.',
                        icon: Icons.mic_rounded,
                        color: const Color(0xFFFCEDEE),
                      ),

                      _buildStepCard(
                        number: '4',
                        title: 'Get Your Score',
                        description:
                            'Aplikasi akan menampilkan skor dan feedback latihan.',
                        icon: Icons.star_rounded,
                        color: AppTheme.softGreen,
                      ),

                      _buildNoteCard(),
                      const SizedBox(height: 14),
                      _buildInternetNoteCard(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    return LearningHeader(
      title: 'How to Play',
      showBackButton: true,
      onBack: () {
        Navigator.pop(context);
      },
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.softBeige,
        borderRadius: BorderRadius.circular(34),
      ),
      child: const Column(
        children: [
          Icon(Icons.lightbulb_rounded, size: 58, color: AppTheme.goldDark),
          SizedBox(height: 12),
          Text(
            'Let’s Learn Together!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppTheme.darkText,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Dengarkan contoh, ucapkan kata, lalu lihat skor pengucapanmu.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.mutedText,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required String number,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(icon, color: AppTheme.darkText, size: 34),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppTheme.gold,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.mutedText,
                    height: 1.35,
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

  Widget _buildNoteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F6F8),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_rounded, color: Color(0xFF2678A8), size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Gunakan aplikasi di tempat yang tenang agar suara lebih mudah dikenali.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF2678A8),
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInternetNoteCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.gold.withValues(alpha: 0.28),
          width: 1.5,
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.wifi_rounded, color: AppTheme.goldDark, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Mode rekam butuh internet agar hasil suara lebih baik.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.mutedText,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
