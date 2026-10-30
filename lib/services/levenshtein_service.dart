enum PronunciationScoreCategory {
  excellent,
  developing,
  retry,
}

class LevenshteinService {
  static const int excellentMinimumScore = 90;
  static const int developingMinimumScore = 50;

  static String normalizeText(String text) {
    return text.toLowerCase().trim().replaceAll(RegExp(r'[^a-z]'), '');
  }

  static int calculateDistance(String target, String recognized) {
    final String source = normalizeText(target);
    final String result = normalizeText(recognized);

    final int sourceLength = source.length;
    final int resultLength = result.length;

    if (sourceLength == 0) return resultLength;
    if (resultLength == 0) return sourceLength;

    final List<List<int>> matrix = List.generate(
      sourceLength + 1,
      (_) => List.filled(resultLength + 1, 0),
    );

    for (int i = 0; i <= sourceLength; i++) {
      matrix[i][0] = i;
    }

    for (int j = 0; j <= resultLength; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= sourceLength; i++) {
      for (int j = 1; j <= resultLength; j++) {
        final int cost = source[i - 1] == result[j - 1] ? 0 : 1;

        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[sourceLength][resultLength];
  }

  static int calculateScore(String target, String recognized) {
    final String normalizedTarget = normalizeText(target);
    final String normalizedRecognized = normalizeText(recognized);

    if (normalizedTarget.isEmpty || normalizedRecognized.isEmpty) {
      return 0;
    }

    final int distance = calculateDistance(target, recognized);

    final int maxLength = normalizedTarget.length > normalizedRecognized.length
        ? normalizedTarget.length
        : normalizedRecognized.length;

    if (maxLength == 0) return 0;

    final double score = (1 - (distance / maxLength)) * 100;

    return score.clamp(0, 100).round();
  }

  static PronunciationScoreCategory getCategory(int score) {
    final normalizedScore = score.clamp(0, 100);

    if (normalizedScore >= excellentMinimumScore) {
      return PronunciationScoreCategory.excellent;
    }

    if (normalizedScore >= developingMinimumScore) {
      return PronunciationScoreCategory.developing;
    }

    return PronunciationScoreCategory.retry;
  }

  static String getTitle(int score) {
    switch (getCategory(score)) {
      case PronunciationScoreCategory.excellent:
        return 'Hebat!';
      case PronunciationScoreCategory.developing:
        return 'Sudah Bagus!';
      case PronunciationScoreCategory.retry:
        return 'Coba Lagi!';
    }
  }

  static String getFeedback(int score) {
    switch (getCategory(score)) {
      case PronunciationScoreCategory.excellent:
        return 'Kata kamu berhasil dikenali dengan tepat.';
      case PronunciationScoreCategory.developing:
        return 'Kata yang dikenali sudah mendekati target. Coba ulangi lebih jelas.';
      case PronunciationScoreCategory.retry:
        return 'Dengarkan contoh suara, lalu ucapkan kembali dengan pelan.';
    }
  }
}
