class PracticeResult {
  final int? id;
  final String word;
  final String category;
  final String recognizedWord;
  final int distance;
  final int score;
  final String feedback;
  final String asrMethod;
  final String createdAt;

  PracticeResult({
    this.id,
    required this.word,
    required this.category,
    required this.recognizedWord,
    required this.distance,
    required this.score,
    required this.feedback,
    this.asrMethod = 'Google ASR',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'word': word,
      'category': category,
      'recognized_word': recognizedWord,
      'distance': distance,
      'score': score,
      'feedback': feedback,
      'asr_method': asrMethod,
      'created_at': createdAt,
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  factory PracticeResult.fromMap(Map<String, dynamic> map) {
    return PracticeResult(
      id: map['id'] as int?,
      word: map['word'] as String,
      category: map['category'] as String,
      recognizedWord: map['recognized_word'] as String,
      distance: map['distance'] as int,
      score: map['score'] as int,
      feedback: map['feedback'] as String,
      asrMethod: (map['asr_method'] as String?) ?? 'Google ASR',
      createdAt: map['created_at'] as String,
    );
  }
}
