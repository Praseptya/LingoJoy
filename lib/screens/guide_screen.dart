import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  Widget guideItem({
    required int number,
    required String title,
    required String description,
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
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withValues(alpha: 0.18),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$number. $title',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.softText,
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
      appBar: AppBar(title: const Text('Petunjuk Penggunaan')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          guideItem(
            number: 1,
            title: 'Pilih Kategori',
            description:
                'Pilih kategori kata seperti angka, hewan, buah, benda, atau warna.',
            icon: Icons.category,
            color: AppTheme.primaryBlue,
          ),
          guideItem(
            number: 2,
            title: 'Dengarkan Contoh',
            description:
                'Tekan tombol suara untuk mendengarkan contoh pengucapan Bahasa Inggris.',
            icon: Icons.volume_up,
            color: AppTheme.green,
          ),
          guideItem(
            number: 3,
            title: 'Ucapkan Kata',
            description:
                'Tekan tombol mikrofon lalu ucapkan kata sesuai gambar yang muncul.',
            icon: Icons.mic,
            color: AppTheme.orange,
          ),
          guideItem(
            number: 4,
            title: 'Lihat Skor',
            description:
                'Aplikasi akan menampilkan skor dan feedback latihan secara otomatis.',
            icon: Icons.star,
            color: AppTheme.pink,
          ),
        ],
      ),
    );
  }
}
