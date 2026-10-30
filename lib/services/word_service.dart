import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/word_model.dart';

class WordService {
  Future<List<WordModel>> loadWords() async {
    final String jsonString = await rootBundle.loadString(
      'assets/data/words_seed.json',
    );

    final List<dynamic> jsonData = json.decode(jsonString);

    return jsonData.map((item) {
      return WordModel.fromJson(item);
    }).toList();
  }

  Future<List<String>> loadCategories() async {
    final words = await loadWords();

    final categories = words.map((word) => word.category).toSet().toList();

    return categories;
  }

  Future<List<WordModel>> loadWordsByCategory(String category) async {
    final words = await loadWords();

    final filteredWords = words.where((word) => word.category == category).toList();

    if (category.toLowerCase() != 'angka') {
      filteredWords.sort(
        (a, b) => a.word.toLowerCase().compareTo(b.word.toLowerCase()),
      );
    }

    return filteredWords;
  }
}
