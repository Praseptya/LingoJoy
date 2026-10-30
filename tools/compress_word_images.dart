import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

void main(List<String> args) async {
  const inputDirPath = 'assets/images/words_clean';
  const outputDirPath = 'assets/images/words_compressed';

  const maxDimension = 512; // bisa ubah ke 600 kalau mau
  const jpgQuality = 85;
  const pngCompressionLevel = 6; // 0-9

  final inputDir = Directory(inputDirPath);
  final outputDir = Directory(outputDirPath);

  if (!inputDir.existsSync()) {
    print('Folder input tidak ditemukan: $inputDirPath');
    exit(1);
  }

  outputDir.createSync(recursive: true);

  final supportedExtensions = {'.png', '.jpg', '.jpeg', '.webp'};

  final imageFiles =
      inputDir
          .listSync()
          .whereType<File>()
          .where(
            (file) => supportedExtensions.contains(
              p.extension(file.path).toLowerCase(),
            ),
          )
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  if (imageFiles.isEmpty) {
    print('Tidak ada gambar yang ditemukan di $inputDirPath');
    return;
  }

  int totalOriginalBytes = 0;
  int totalCompressedBytes = 0;
  int processedCount = 0;
  int skippedCount = 0;

  final report = StringBuffer()
    ..writeln('# IMAGE COMPRESSION REPORT')
    ..writeln()
    ..writeln(
      '| File | Original Size | New Size | Original Dim | New Dim | Saving |',
    )
    ..writeln(
      '|------|---------------|----------|--------------|---------|--------|',
    );

  for (final file in imageFiles) {
    try {
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);

      if (decoded == null) {
        skippedCount++;
        print('Skip (gagal decode): ${p.basename(file.path)}');
        continue;
      }

      totalOriginalBytes += bytes.length;

      img.Image outputImage = decoded;

      final originalWidth = decoded.width;
      final originalHeight = decoded.height;

      if (decoded.width >= decoded.height) {
        if (decoded.width > maxDimension) {
          outputImage = img.copyResize(decoded, width: maxDimension);
        }
      } else {
        if (decoded.height > maxDimension) {
          outputImage = img.copyResize(decoded, height: maxDimension);
        }
      }

      final ext = p.extension(file.path).toLowerCase();
      late List<int> encodedBytes;

      if (ext == '.png') {
        encodedBytes = img.encodePng(outputImage, level: pngCompressionLevel);
      } else if (ext == '.jpg' || ext == '.jpeg') {
        encodedBytes = img.encodeJpg(outputImage, quality: jpgQuality);
      } else if (ext == '.webp') {
        encodedBytes = img.encodePng(outputImage, level: pngCompressionLevel);
      } else {
        skippedCount++;
        print('Skip (format tidak didukung): ${p.basename(file.path)}');
        continue;
      }

      final outputPath = p.join(outputDir.path, p.basename(file.path));
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(encodedBytes, flush: true);

      totalCompressedBytes += encodedBytes.length;
      processedCount++;

      final saving = _percentSaving(bytes.length, encodedBytes.length);

      report.writeln(
        '| ${p.basename(file.path)} '
        '| ${_formatBytes(bytes.length)} '
        '| ${_formatBytes(encodedBytes.length)} '
        '| ${originalWidth}x$originalHeight '
        '| ${outputImage.width}x${outputImage.height} '
        '| $saving |',
      );

      print(
        'OK  ${p.basename(file.path)} '
        '(${originalWidth}x$originalHeight -> ${outputImage.width}x${outputImage.height}) '
        '${_formatBytes(bytes.length)} -> ${_formatBytes(encodedBytes.length)}',
      );
    } catch (e) {
      skippedCount++;
      print('Error pada ${p.basename(file.path)}: $e');
    }
  }

  final reportFile = File('IMAGE_COMPRESSION_REPORT.md');
  await reportFile.writeAsString(report.toString());

  print('');
  print('=== SELESAI ===');
  print('Diproses : $processedCount file');
  print('Dilewati : $skippedCount file');
  print('Ukuran awal  : ${_formatBytes(totalOriginalBytes)}');
  print('Ukuran akhir : ${_formatBytes(totalCompressedBytes)}');
  print(
    'Hemat        : ${_percentSaving(totalOriginalBytes, totalCompressedBytes)}',
  );
  print('Folder hasil : $outputDirPath');
  print('Report       : IMAGE_COMPRESSION_REPORT.md');
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
}

String _percentSaving(int before, int after) {
  if (before <= 0) return '0%';
  final saving = ((before - after) / before) * 100;
  return '${saving.toStringAsFixed(1)}%';
}
