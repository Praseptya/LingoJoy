import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'web_tts_adapter.dart';

class TtsException implements Exception {
  final String message;

  TtsException(this.message);

  @override
  String toString() => message;
}

class VoiceRssTtsService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  static final Map<String, Uint8List> _audioCache = {};

  Uri _buildUri(String text) {
    return Uri.https('api.voicerss.org', '/', {
      'key': ApiConfig.voiceRssApiKey,
      'hl': 'en-us',
      'v': 'Mary',
      'r': '-2',
      'c': 'MP3',
      'f': '24khz_16bit_mono',
      'src': text,
    });
  }

  Future<Uint8List> _downloadAudio(String text) async {
    final cacheKey = text.toLowerCase().trim();

    if (_audioCache.containsKey(cacheKey)) {
      return _audioCache[cacheKey]!;
    }

    try {
      final uri = _buildUri(text);

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw TtsException(
          'TTS tidak dapat digunakan. Server sedang bermasalah.',
        );
      }

      final contentType = response.headers['content-type'] ?? '';

      if (contentType.contains('text')) {
        final errorMessage = utf8.decode(response.bodyBytes);

        throw TtsException('TTS tidak dapat digunakan. $errorMessage');
      }

      _audioCache[cacheKey] = response.bodyBytes;

      return response.bodyBytes;
    } on TimeoutException {
      throw TtsException(
        'TTS tidak dapat digunakan karena koneksi internet terlalu lambat. '
        'Silakan coba lagi.',
      );
    } on http.ClientException {
      throw TtsException(
        'TTS tidak dapat digunakan karena koneksi internet tidak tersedia. '
        'Silakan aktifkan data internet lalu coba lagi.',
      );
    } on TtsException {
      rethrow;
    } catch (_) {
      throw TtsException('TTS tidak dapat digunakan. Silakan coba lagi.');
    }
  }

  Future<void> preload(String text) async {
    // Saat run di Chrome, gunakan Web Speech API bawaan browser.
    // Tidak perlu preload audio VoiceRSS agar tidak terkena masalah CORS/DNS web.
    if (kIsWeb) {
      return;
    }

    final cacheKey = text.toLowerCase().trim();

    if (_audioCache.containsKey(cacheKey)) {
      return;
    }

    await _downloadAudio(text);
  }

  Future<void> speak(String text) async {
    if (kIsWeb) {
      await WebTtsAdapter.speak(text);
      return;
    }

    final audioBytes = await _downloadAudio(text);

    await _audioPlayer.stop();

    await _audioPlayer.play(BytesSource(audioBytes));
  }

  Future<void> stop() async {
    if (kIsWeb) {
      await WebTtsAdapter.stop();
      return;
    }

    await _audioPlayer.stop();
  }

  Future<void> dispose() async {
    if (kIsWeb) {
      await WebTtsAdapter.dispose();
      return;
    }

    await _audioPlayer.dispose();
  }
}
