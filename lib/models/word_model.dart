class WordModel {
  final int id;
  final String word;
  final String category;
  final String ttsText;
  final String imageName;
  final String difficulty;

  WordModel({
    required this.id,
    required this.word,
    required this.category,
    required this.ttsText,
    required this.imageName,
    required this.difficulty,
  });

  factory WordModel.fromJson(Map<String, dynamic> json) {
    return WordModel(
      id: json['id'],
      word: json['word'],
      category: json['category'],
      ttsText: json['tts_text'],
      imageName: json['image_name'],
      difficulty: json['difficulty'],
    );
  }
}
