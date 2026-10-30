import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

class LingoJoyWavData {
  final int sampleRate;
  final int channels;
  final int bitsPerSample;
  final List<double> samples;

  const LingoJoyWavData({
    required this.sampleRate,
    required this.channels,
    required this.bitsPerSample,
    required this.samples,
  });

  double get durationSeconds {
    if (sampleRate <= 0) return 0.0;
    return samples.length / sampleRate;
  }
}

class LingoJoyWavReaderService {
  LingoJoyWavReaderService._internal();

  static final LingoJoyWavReaderService instance =
      LingoJoyWavReaderService._internal();

  Future<LingoJoyWavData> readWavFile(String filePath) async {
    final file = File(filePath);

    if (!file.existsSync()) {
      throw FileSystemException('File WAV tidak ditemukan.', filePath);
    }

    final bytes = await file.readAsBytes();
    final data = ByteData.sublistView(bytes);

    final riff = String.fromCharCodes(bytes.sublist(0, 4));
    final wave = String.fromCharCodes(bytes.sublist(8, 12));

    if (riff != 'RIFF' || wave != 'WAVE') {
      throw FormatException('File bukan format WAV valid.');
    }

    int offset = 12;

    int? sampleRate;
    int? channels;
    int? bitsPerSample;
    int? dataStart;
    int? dataSize;

    while (offset + 8 <= bytes.length) {
      final chunkId = String.fromCharCodes(bytes.sublist(offset, offset + 4));

      final chunkSize = data.getUint32(offset + 4, Endian.little);

      final chunkDataStart = offset + 8;

      if (chunkId == 'fmt ') {
        final audioFormat = data.getUint16(chunkDataStart, Endian.little);

        channels = data.getUint16(chunkDataStart + 2, Endian.little);

        sampleRate = data.getUint32(chunkDataStart + 4, Endian.little);

        bitsPerSample = data.getUint16(chunkDataStart + 14, Endian.little);

        if (audioFormat != 1) {
          throw FormatException('WAV bukan PCM. Audio format: $audioFormat');
        }
      }

      if (chunkId == 'data') {
        dataStart = chunkDataStart;
        dataSize = chunkSize;
        break;
      }

      offset = chunkDataStart + chunkSize;

      if (offset.isOdd) {
        offset += 1;
      }
    }

    if (sampleRate == null ||
        channels == null ||
        bitsPerSample == null ||
        dataStart == null ||
        dataSize == null) {
      throw FormatException('Header WAV tidak lengkap.');
    }

    if (bitsPerSample != 16) {
      throw FormatException(
        'Saat ini hanya mendukung WAV PCM 16-bit. '
        'bitsPerSample: $bitsPerSample',
      );
    }

    final samples = <double>[];
    final bytesPerSample = bitsPerSample ~/ 8;
    final frameSize = bytesPerSample * channels;

    for (int i = 0; i + frameSize <= dataSize; i += frameSize) {
      double monoValue = 0.0;

      for (int channelIndex = 0; channelIndex < channels; channelIndex++) {
        final sampleOffset = dataStart + i + channelIndex * bytesPerSample;

        final intSample = data.getInt16(sampleOffset, Endian.little);

        monoValue += intSample / 32768.0;
      }

      monoValue /= channels;
      samples.add(monoValue);
    }

    final wavData = LingoJoyWavData(
      sampleRate: sampleRate,
      channels: channels,
      bitsPerSample: bitsPerSample,
      samples: samples,
    );

    debugPrint('LINGOJOY WAV READ SUCCESS');
    debugPrint('Sample rate    : ${wavData.sampleRate}');
    debugPrint('Channels       : ${wavData.channels}');
    debugPrint('Bits per sample: ${wavData.bitsPerSample}');
    debugPrint('Samples        : ${wavData.samples.length}');
    debugPrint('Duration       : ${wavData.durationSeconds} seconds');

    return wavData;
  }
}
