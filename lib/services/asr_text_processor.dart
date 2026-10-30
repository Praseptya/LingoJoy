import 'levenshtein_service.dart';

class AsrQualityDecision {
  final String candidate;
  final bool shouldRetry;
  final String retryMessage;
  final int distance;
  final int score;

  const AsrQualityDecision({
    required this.candidate,
    required this.shouldRetry,
    required this.retryMessage,
    required this.distance,
    required this.score,
  });
}

class AsrTextProcessor {
  // Daftar ini hanya berisi perbedaan ejaan yang dapat mewakili bunyi
  // yang sama. Kata yang hanya terdengar mirip tidak diterima sebagai benar.
  static final Map<String, List<String>> allowedHomophonesByTarget = {
    // Numbers
    'one': ['won'],
    'two': ['to', 'too'],
    'four': ['for', 'fore'],
    'eight': ['ate'],

    // Animals / spelling variants
    'dog': ['dawg'],

    // Fruits
    'pear': ['pair'],

    // Colors
    'blue': ['blew'],
    'red': ['read'],

    // Body parts
    'eye': ['i'],
    'hair': ['hare'],

    // Transport
    'plane': ['plain'],
  };

  // Alias frasa yang masih setara secara bentuk kata, bukan koreksi pelafalan.
  // Contoh: ASR kadang menulis "motorcycle" sebagai "motor cycle".
  static final Map<String, List<String>> allowedPhraseAliasesByTarget = {
    'motorcycle': ['motor cycle'],
  };

  static final Set<String> fillerWords = {
    'a',
    'an',
    'the',
    'this',
    'that',
    'it',
    'its',
    'is',
    'are',
    'was',
    'were',
    'my',
    'your',
    'you',
    'say',
    'said',
    'word',
    'number',
  };

  static String normalize(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static List<String> tokenize(String text) {
    final normalized = normalize(text);

    if (normalized.isEmpty) {
      return [];
    }

    return normalized
        .split(' ')
        .where((word) => word.trim().isNotEmpty)
        .toList();
  }

  static bool isAllowedHomophone({
    required String target,
    required String candidate,
  }) {
    final normalizedTarget = normalize(target);
    final normalizedCandidate = normalize(candidate);

    final homophones = allowedHomophonesByTarget[normalizedTarget] ?? [];

    return homophones.contains(normalizedCandidate);
  }

  static bool isAllowedPhraseAlias({
    required String target,
    required String candidateText,
  }) {
    final normalizedTarget = normalize(target);
    final normalizedCandidate = normalize(candidateText);

    final aliases = allowedPhraseAliasesByTarget[normalizedTarget] ?? [];

    return aliases.contains(normalizedCandidate);
  }

  static List<String> _removeFillers(List<String> words, String target) {
    final normalizedTarget = normalize(target);

    return words.where((word) {
      if (word == normalizedTarget) return true;
      if (isAllowedHomophone(target: normalizedTarget, candidate: word)) {
        return true;
      }

      return !fillerWords.contains(word);
    }).toList();
  }

  static String extractBestCandidate({
    required String targetWord,
    required String recognizedText,
  }) {
    final target = normalize(targetWord);
    final recognized = normalize(recognizedText);

    if (target.isEmpty || recognized.isEmpty) {
      return '';
    }

    if (target == recognized ||
        isAllowedPhraseAlias(target: target, candidateText: recognized)) {
      return target;
    }

    final originalWords = tokenize(recognized);

    if (originalWords.isEmpty) {
      return '';
    }

    // 1. Jika ASR menangkap target secara langsung, pakai target.
    // Contoh: "the cat" -> "cat".
    if (originalWords.contains(target)) {
      return target;
    }

    // 2. Jika ASR menangkap homophone yang diizinkan untuk target,
    // pakai target agar tidak dihukum karena perbedaan tulisan ASR.
    // Contoh target one, ASR won -> one.
    for (final word in originalWords) {
      if (isAllowedHomophone(target: target, candidate: word)) {
        return target;
      }
    }

    final candidateWords = _removeFillers(originalWords, target);

    if (candidateWords.isEmpty) {
      return originalWords.first;
    }

    // 3. Jika hanya satu kata kandidat, gunakan apa adanya.
    // Tidak ada koreksi agresif di sini.
    // Contoh target cat, ASR cut -> cut, bukan cat.
    if (candidateWords.length == 1) {
      return candidateWords.first;
    }

    // 4. Jika ASR menghasilkan beberapa kata, pilih kata paling dekat,
    // tetapi tetap dari kata yang benar-benar keluar dari ASR.
    // Tidak memaksa hasil menjadi target.
    String bestWord = candidateWords.first;
    int bestDistance = LevenshteinService.calculateDistance(target, bestWord);

    for (final word in candidateWords.skip(1)) {
      final distance = LevenshteinService.calculateDistance(target, word);

      if (distance < bestDistance) {
        bestDistance = distance;
        bestWord = word;
      }
    }

    return bestWord;
  }

  static AsrQualityDecision evaluateCandidateQuality({
    required String targetWord,
    required String recognizedText,
    double confidence = -1,
  }) {
    final target = normalize(targetWord);
    final candidate = extractBestCandidate(
      targetWord: targetWord,
      recognizedText: recognizedText,
    );

    if (target.isEmpty || candidate.isEmpty) {
      return const AsrQualityDecision(
        candidate: '',
        shouldRetry: true,
        retryMessage:
            'Suara belum terbaca. Coba ucapkan kata dengan jelas, lalu tekan stop.',
        distance: 0,
        score: 0,
      );
    }

    final distance = LevenshteinService.calculateDistance(target, candidate);
    final score = LevenshteinService.calculateScore(target, candidate);

    final bool acceptedDirectly = isExactOrAllowedHomophone(
      targetWord: target,
      recognizedWord: candidate,
    );

    if (acceptedDirectly) {
      return AsrQualityDecision(
        candidate: target,
        shouldRetry: false,
        retryMessage: '',
        distance: distance,
        score: score,
      );
    }

    final normalizedCandidate = normalize(candidate);
    final int targetLength = target.length;
    final int candidateLength = normalizedCandidate.length;

    // LEVEL 2: target-aware validation gate.
    // Sistem TIDAK mengubah candidate menjadi target/kategori. Sistem hanya
    // menilai apakah hasil ASR terlalu tidak stabil untuk langsung diberi skor.
    // Ini berguna untuk kasus kata pendek seperti pen -> fan/ben atau bag -> make.
    final bool shortWordMismatch = targetLength <= 3 && distance >= 1;
    final bool veryDifferent = score < 50;
    final bool candidateLengthOdd =
        targetLength <= 4 && candidateLength > targetLength + 2;
    final bool lowConfidence = confidence >= 0 && confidence < 0.45;
    final bool lowConfidenceAndNotClose = lowConfidence && score < 85;

    final bool shouldRetry =
        shortWordMismatch ||
        veryDifferent ||
        candidateLengthOdd ||
        lowConfidenceAndNotClose;

    final String retryMessage = shortWordMismatch
        ? 'LingoJoy belum yakin dengan kata yang terbaca. Coba ulangi satu kali dengan suara jelas.'
        : 'Suara belum terbaca dengan baik. Coba ulangi satu kali lagi, ya.';

    return AsrQualityDecision(
      candidate: candidate,
      shouldRetry: shouldRetry,
      retryMessage: retryMessage,
      distance: distance,
      score: score,
    );
  }

  static bool isExactOrAllowedHomophone({
    required String targetWord,
    required String recognizedWord,
  }) {
    final target = normalize(targetWord);
    final recognized = normalize(recognizedWord);

    if (target.isEmpty || recognized.isEmpty) {
      return false;
    }

    return target == recognized ||
        isAllowedHomophone(target: target, candidate: recognized) ||
        isAllowedPhraseAlias(target: target, candidateText: recognized);
  }
}
