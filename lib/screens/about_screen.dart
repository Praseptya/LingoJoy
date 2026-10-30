import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Widget infoBox({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.18),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.softText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.darkText,
                    fontWeight: FontWeight.bold,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softBlue,
      appBar: AppBar(title: const Text('Tentang Aplikasi')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Column(
              children: [
                Icon(Icons.record_voice_over, size: 72, color: Colors.white),
                SizedBox(height: 14),
                Text(
                  'LingoJoy',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Aplikasi pembelajaran pengucapan Bahasa Inggris untuk anak usia dini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          infoBox(
            title: 'Judul Penelitian',
            value:
                'Model Speech Recognition Menggunakan Google ASR dan Autoregressive Predictive Coding (APC)–Long Short-Term Memory (LSTM) untuk Mendukung Pembelajaran Pronunciation',
            icon: Icons.school,
            color: AppTheme.primaryBlue,
          ),
          infoBox(
            title: 'Peneliti',
            value: 'Muhamad Arya Praseptya',
            icon: Icons.person,
            color: AppTheme.green,
          ),
          infoBox(
            title: 'Teknologi',
            value:
                'Flutter, Google ASR, APC-LSTM, TensorFlow Lite, MFCC, Text-to-Speech, Levenshtein Distance, SQLite',
            icon: Icons.memory,
            color: AppTheme.orange,
          ),
        ],
      ),
    );
  }
}
