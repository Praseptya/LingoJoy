import 'dart:convert';
import 'dart:io';

class WordAssetItem {
  final int? id;
  final String word;
  final String category;
  final String imageName;

  WordAssetItem({
    required this.id,
    required this.word,
    required this.category,
    required this.imageName,
  });
}

void main(List<String> args) {
  final root = Directory.current;
  final wordFile = File('${root.path}/assets/data/words_seed.json');
  final imageDir = Directory('${root.path}/assets/images/words');
  final pubspecFile = File('${root.path}/pubspec.yaml');
  final outputFile = File('${root.path}/ASSET_REPORT.md');

  if (!wordFile.existsSync()) {
    stderr.writeln('ERROR: assets/data/words_seed.json tidak ditemukan. Jalankan script ini dari root project Flutter.');
    exit(1);
  }

  if (!imageDir.existsSync()) {
    stderr.writeln('ERROR: assets/images/words/ tidak ditemukan. Jalankan script ini dari root project Flutter.');
    exit(1);
  }

  final words = _loadWords(wordFile);
  final existingImages = _listImageFiles(imageDir);
  final existingImageNames = existingImages.map((f) => _basename(f.path)).toList();
  final existingLowerMap = <String, List<String>>{};
  for (final name in existingImageNames) {
    existingLowerMap.putIfAbsent(name.toLowerCase(), () => []).add(name);
  }

  final requiredImageNames = words.map((w) => w.imageName).toList();
  final requiredImageSet = requiredImageNames.toSet();
  final requiredLowerSet = requiredImageNames.map((e) => e.toLowerCase()).toSet();

  final missing = <WordAssetItem>[];
  final caseMismatch = <String, List<String>>{};
  for (final item in words) {
    final exactFile = File('${imageDir.path}/${item.imageName}');
    if (!exactFile.existsSync()) {
      final lowerMatches = existingLowerMap[item.imageName.toLowerCase()] ?? [];
      if (lowerMatches.isNotEmpty) {
        caseMismatch[item.imageName] = lowerMatches;
      } else {
        missing.add(item);
      }
    }
  }

  final unused = existingImageNames
      .where((name) => !requiredImageSet.contains(name) && !requiredLowerSet.contains(name.toLowerCase()))
      .toList()
    ..sort();

  final duplicateIds = _findDuplicates(words.map((w) => w.id?.toString() ?? '').where((e) => e.isNotEmpty));
  final duplicateWords = _findDuplicates(words.map((w) => '${w.category.toLowerCase()}::${w.word.toLowerCase()}'));
  final duplicateImages = _findDuplicates(requiredImageNames.map((e) => e.toLowerCase()));
  final invalidImageNames = requiredImageNames.where((name) => !_isValidAssetName(name)).toList()..sort();

  final categoryMap = <String, List<WordAssetItem>>{};
  for (final item in words) {
    categoryMap.putIfAbsent(item.category, () => []).add(item);
  }

  final pubspecStatus = _checkPubspec(pubspecFile);
  final report = _buildReport(
    words: words,
    categoryMap: categoryMap,
    existingImageNames: existingImageNames,
    missing: missing,
    unused: unused,
    caseMismatch: caseMismatch,
    duplicateIds: duplicateIds,
    duplicateWords: duplicateWords,
    duplicateImages: duplicateImages,
    invalidImageNames: invalidImageNames,
    pubspecStatus: pubspecStatus,
  );

  outputFile.writeAsStringSync(report);

  stdout.writeln('Asset check selesai.');
  stdout.writeln('Total kata        : ${words.length}');
  stdout.writeln('Total kategori    : ${categoryMap.length}');
  stdout.writeln('Gambar tersedia   : ${existingImageNames.length}');
  stdout.writeln('Gambar dibutuhkan : ${requiredImageSet.length}');
  stdout.writeln('Missing image     : ${missing.length}');
  stdout.writeln('Unused image      : ${unused.length}');
  stdout.writeln('Case mismatch     : ${caseMismatch.length}');
  stdout.writeln('Report dibuat     : ASSET_REPORT.md');

  if (missing.isNotEmpty || caseMismatch.isNotEmpty || duplicateIds.isNotEmpty || duplicateWords.isNotEmpty || duplicateImages.isNotEmpty || invalidImageNames.isNotEmpty) {
    stdout.writeln('\nStatus: PERLU DICEK. Buka ASSET_REPORT.md untuk detail.');
  } else {
    stdout.writeln('\nStatus: AMAN. Data kata dan gambar sudah sinkron.');
  }
}

List<WordAssetItem> _loadWords(File file) {
  final raw = file.readAsStringSync();
  final decoded = jsonDecode(raw);
  if (decoded is! List) {
    stderr.writeln('ERROR: words_seed.json harus berupa JSON array/list.');
    exit(1);
  }

  final result = <WordAssetItem>[];
  for (var i = 0; i < decoded.length; i++) {
    final item = decoded[i];
    if (item is! Map<String, dynamic>) {
      stderr.writeln('ERROR: Item index $i bukan object JSON.');
      exit(1);
    }

    final word = (item['word'] ?? '').toString().trim();
    final category = (item['category'] ?? '').toString().trim();
    final imageName = (item['image_name'] ?? '').toString().trim();
    final idValue = item['id'];
    final id = idValue is int ? idValue : int.tryParse(idValue?.toString() ?? '');

    if (word.isEmpty || category.isEmpty || imageName.isEmpty) {
      stderr.writeln('ERROR: Item index $i wajib punya word, category, dan image_name.');
      exit(1);
    }

    result.add(WordAssetItem(id: id, word: word, category: category, imageName: imageName));
  }
  return result;
}

List<File> _listImageFiles(Directory dir) {
  const allowed = {'.png', '.jpg', '.jpeg', '.webp'};
  final files = <File>[];
  for (final entity in dir.listSync(recursive: false)) {
    if (entity is File) {
      final name = _basename(entity.path).toLowerCase();
      final ext = name.contains('.') ? name.substring(name.lastIndexOf('.')) : '';
      if (allowed.contains(ext)) {
        files.add(entity);
      }
    }
  }
  files.sort((a, b) => _basename(a.path).compareTo(_basename(b.path)));
  return files;
}

String _basename(String path) {
  return path.split(Platform.pathSeparator).last;
}

bool _isValidAssetName(String name) {
  final regex = RegExp(r'^[a-z0-9_\-]+\.(png|jpg|jpeg|webp)$');
  return regex.hasMatch(name);
}

List<String> _findDuplicates(Iterable<String> values) {
  final counts = <String, int>{};
  for (final value in values) {
    counts[value] = (counts[value] ?? 0) + 1;
  }
  final duplicates = counts.entries.where((e) => e.value > 1).map((e) => e.key).toList()..sort();
  return duplicates;
}

String _checkPubspec(File pubspecFile) {
  if (!pubspecFile.existsSync()) {
    return 'pubspec.yaml tidak ditemukan.';
  }

  final text = pubspecFile.readAsStringSync();
  final hasData = text.contains('assets/data/') || text.contains('assets/data/words_seed.json');
  final hasImages = text.contains('assets/images/') || text.contains('assets/images/words/');

  if (hasData && hasImages) {
    return 'OK: pubspec.yaml memuat asset data dan gambar.';
  }

  final missing = <String>[];
  if (!hasData) missing.add('assets/data/');
  if (!hasImages) missing.add('assets/images/ atau assets/images/words/');
  return 'PERLU CEK: pubspec.yaml belum terdeteksi memuat ${missing.join(' dan ')}.';
}

String _buildReport({
  required List<WordAssetItem> words,
  required Map<String, List<WordAssetItem>> categoryMap,
  required List<String> existingImageNames,
  required List<WordAssetItem> missing,
  required List<String> unused,
  required Map<String, List<String>> caseMismatch,
  required List<String> duplicateIds,
  required List<String> duplicateWords,
  required List<String> duplicateImages,
  required List<String> invalidImageNames,
  required String pubspecStatus,
}) {
  final buffer = StringBuffer();
  final requiredUnique = words.map((w) => w.imageName).toSet().length;
  final availableRequired = requiredUnique - missing.length - caseMismatch.length;

  buffer.writeln('# ASSET REPORT');
  buffer.writeln();
  buffer.writeln('Generated by `tools/check_assets.dart`.');
  buffer.writeln();
  buffer.writeln('## Summary');
  buffer.writeln();
  buffer.writeln('| Item | Jumlah |');
  buffer.writeln('|---|---:|');
  buffer.writeln('| Total kata | ${words.length} |');
  buffer.writeln('| Total kategori | ${categoryMap.length} |');
  buffer.writeln('| Gambar dibutuhkan unik | $requiredUnique |');
  buffer.writeln('| Gambar tersedia di folder | ${existingImageNames.length} |');
  buffer.writeln('| Gambar cocok exact | $availableRequired |');
  buffer.writeln('| Missing image | ${missing.length} |');
  buffer.writeln('| Unused image | ${unused.length} |');
  buffer.writeln('| Case mismatch | ${caseMismatch.length} |');
  buffer.writeln();
  buffer.writeln('**Pubspec:** $pubspecStatus');
  buffer.writeln();

  buffer.writeln('## Jumlah Kata per Kategori');
  buffer.writeln();
  buffer.writeln('| Kategori | Jumlah kata |');
  buffer.writeln('|---|---:|');
  final categories = categoryMap.keys.toList()..sort();
  for (final category in categories) {
    buffer.writeln('| $category | ${categoryMap[category]!.length} |');
  }
  buffer.writeln();

  buffer.writeln('## Missing Images');
  buffer.writeln();
  if (missing.isEmpty) {
    buffer.writeln('Tidak ada missing image.');
  } else {
    final groupedMissing = <String, List<WordAssetItem>>{};
    for (final item in missing) {
      groupedMissing.putIfAbsent(item.category, () => []).add(item);
    }
    final missingCategories = groupedMissing.keys.toList()..sort();
    for (final category in missingCategories) {
      buffer.writeln('### $category');
      final items = groupedMissing[category]!..sort((a, b) => a.imageName.compareTo(b.imageName));
      for (final item in items) {
        buffer.writeln('- `${item.imageName}` untuk word `${item.word}`');
      }
      buffer.writeln();
    }
  }
  buffer.writeln();

  buffer.writeln('## Case Mismatch');
  buffer.writeln();
  if (caseMismatch.isEmpty) {
    buffer.writeln('Tidak ada masalah huruf besar/kecil pada nama file.');
  } else {
    caseMismatch.forEach((requiredName, matches) {
      buffer.writeln('- JSON membutuhkan `$requiredName`, tetapi folder berisi `${matches.join(', ')}`. Samakan nama file persis.');
    });
  }
  buffer.writeln();

  buffer.writeln('## Unused Images');
  buffer.writeln();
  if (unused.isEmpty) {
    buffer.writeln('Tidak ada unused image.');
  } else {
    for (final name in unused) {
      buffer.writeln('- `$name`');
    }
  }
  buffer.writeln();

  buffer.writeln('## Duplicate Check');
  buffer.writeln();
  buffer.writeln('### Duplicate ID');
  if (duplicateIds.isEmpty) {
    buffer.writeln('Tidak ada duplicate ID.');
  } else {
    for (final id in duplicateIds) {
      buffer.writeln('- `$id`');
    }
  }
  buffer.writeln();

  buffer.writeln('### Duplicate Word dalam Kategori');
  if (duplicateWords.isEmpty) {
    buffer.writeln('Tidak ada duplicate word dalam kategori yang sama.');
  } else {
    for (final item in duplicateWords) {
      buffer.writeln('- `$item`');
    }
  }
  buffer.writeln();

  buffer.writeln('### Duplicate Image Reference');
  if (duplicateImages.isEmpty) {
    buffer.writeln('Tidak ada duplicate image reference.');
  } else {
    for (final image in duplicateImages) {
      buffer.writeln('- `$image`');
    }
  }
  buffer.writeln();

  buffer.writeln('## Invalid Image Names');
  buffer.writeln();
  if (invalidImageNames.isEmpty) {
    buffer.writeln('Semua nama image di JSON sudah aman.');
  } else {
    buffer.writeln('Nama file sebaiknya huruf kecil, tanpa spasi, dan pakai ekstensi png/jpg/jpeg/webp.');
    for (final name in invalidImageNames) {
      buffer.writeln('- `$name`');
    }
  }
  buffer.writeln();

  buffer.writeln('## Checklist Penggunaan');
  buffer.writeln();
  buffer.writeln('1. Tambahkan gambar yang missing ke `assets/images/words/`.');
  buffer.writeln('2. Pastikan nama file sama persis dengan `image_name` di `words_seed.json`.');
  buffer.writeln('3. Setelah menambah gambar, jalankan ulang: `dart run tools/check_assets.dart`.');
  buffer.writeln('4. Jika report sudah aman, jalankan `flutter pub get` dan `flutter run`.');

  return buffer.toString();
}
