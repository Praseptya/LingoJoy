// ignore_for_file: deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class AsrListenResult {
  final String words;
  final bool isFinal;
  final double confidence;

  const AsrListenResult({
    required this.words,
    required this.isFinal,
    required this.confidence,
  });
}

/// Satu wrapper ASR untuk seluruh sesi aplikasi.
///
/// `speech_to_text` menyarankan satu instance dan satu kali initialize per
/// sesi aplikasi. Callback halaman tetap dapat berganti karena callback native
/// diarahkan ke listener aktif yang disimpan di wrapper ini.
class SpeechService {
  SpeechService._internal();

  /// Batas tunggu internal plugin setelah engine native berhenti mendengar.
  /// PracticeScreen harus menunggu sedikit lebih lama daripada nilai ini.
  static const Duration finalResultTimeout = Duration(seconds: 4);

  static final SpeechService _instance = SpeechService._internal();

  factory SpeechService() => _instance;

  final stt.SpeechToText _speechToText = stt.SpeechToText();

  bool _isInitialized = false;
  String _selectedLocaleId = 'en_US';
  ValueChanged<String>? _statusListener;
  ValueChanged<String>? _errorListener;

  bool get isListening => _speechToText.isListening;
  bool get isAvailable => _speechToText.isAvailable;
  String get selectedLocaleId => _selectedLocaleId;
  String get lastRecognizedWords => _speechToText.lastRecognizedWords;
  String get lastStatus => _speechToText.lastStatus;

  Future<bool> initialize({
    required ValueChanged<String> onStatus,
    required ValueChanged<String> onError,
  }) async {
    // Listener halaman boleh diperbarui walaupun engine hanya diinisialisasi
    // satu kali.
    _statusListener = onStatus;
    _errorListener = onError;

    if (_isInitialized) {
      return _speechToText.isAvailable;
    }

    _isInitialized = await _speechToText.initialize(
      onStatus: (status) {
        debugPrint('ASR native status: $status');
        _statusListener?.call(status);
      },
      onError: (error) {
        debugPrint(
          'ASR native error: ${error.errorMsg} | permanent=${error.permanent}',
        );
        _errorListener?.call(error.errorMsg);
      },
      // Beri waktu lebih panjang agar hasil final yang terlambat masih dapat
      // diterima setelah engine native menyatakan sesi selesai.
      finalTimeout: finalResultTimeout,
    );

    if (_isInitialized) {
      await _selectBestEnglishLocale();
    }

    return _isInitialized;
  }

  void detachListeners() {
    _statusListener = null;
    _errorListener = null;
  }

  Future<void> _selectBestEnglishLocale() async {
    try {
      final locales = await _speechToText.locales();

      if (locales.isEmpty) {
        _selectedLocaleId = 'en_US';
        return;
      }

      const preferredLocales = <String>[
        'en_US',
        'en_GB',
        'en_AU',
        'en_CA',
        'en_IN',
      ];

      for (final preferred in preferredLocales) {
        for (final locale in locales) {
          if (locale.localeId == preferred) {
            _selectedLocaleId = locale.localeId;
            debugPrint('ASR locale selected: $_selectedLocaleId');
            return;
          }
        }
      }

      for (final locale in locales) {
        final localeId = locale.localeId.toLowerCase();

        if (localeId.startsWith('en_') || localeId.startsWith('en-')) {
          _selectedLocaleId = locale.localeId;
          debugPrint('ASR locale selected: $_selectedLocaleId');
          return;
        }
      }

      _selectedLocaleId = 'en_US';
      debugPrint('ASR English locale not found. Fallback: $_selectedLocaleId');
    } catch (e) {
      _selectedLocaleId = 'en_US';
      debugPrint(
        'Failed to read ASR locales. Fallback: $_selectedLocaleId | $e',
      );
    }
  }

  Future<void> startListening({
    required ValueChanged<AsrListenResult> onResult,
    ValueChanged<double>? onSoundLevelChange,
  }) async {
    debugPrint(
      'ASR start listening | locale=$_selectedLocaleId | '
      'finalTimeout=${finalResultTimeout.inMilliseconds}ms | '
      'time=${DateTime.now().toIso8601String()}',
    );

    await _speechToText.listen(
      onSoundLevelChange: onSoundLevelChange,
      onResult: (SpeechRecognitionResult result) {
        onResult(
          AsrListenResult(
            words: result.recognizedWords,
            isFinal: result.finalResult,
            confidence: result.confidence,
          ),
        );
      },
      listenOptions: stt.SpeechListenOptions(
        localeId: _selectedLocaleId,
        listenFor: const Duration(seconds: 12),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: false,
        onDevice: false,
        listenMode: stt.ListenMode.deviceDefault,
      ),
    );
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
  }

  Future<void> cancelListening() async {
    await _speechToText.cancel();
  }
}
