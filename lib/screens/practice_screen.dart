import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/practice_result_model.dart';
import '../models/word_model.dart';
import '../utils/app_theme.dart';
import '../services/levenshtein_service.dart';
import '../services/voice_rss_tts_service.dart';
import '../services/speech_service.dart';
import '../services/asr_text_processor.dart';
import '../services/database_service.dart';
import '../services/perfect_score_notifier.dart';
import '../services/lingojoy_local_asr_service.dart';
import '../widgets/learning_header.dart';
import '../widgets/learning_message.dart';
import 'result_screen.dart';

final LingoJoyLocalAsrService localAsrService =
    LingoJoyLocalAsrService.instance;

class PracticeScreen extends StatefulWidget {
  final WordModel word;

  // Tambahan untuk fitur Next Word
  final List<WordModel>? words;
  final int currentIndex;

  const PracticeScreen({
    super.key,
    required this.word,
    this.words,
    this.currentIndex = 0,
  });

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final VoiceRssTtsService ttsService = VoiceRssTtsService();
  final SpeechService speechService = SpeechService();

  bool isLoadingTts = false;
  bool isSpeechAvailable = false;
  bool isPreparingSpeech = false;
  bool isListening = false;
  bool isProcessingSpeech = false;
  bool canStopSpeech = false;

  String recognizedText = '';
  String micInstruction = 'Tekan untuk mulai bicara';
  double _lastAsrConfidence = -1;
  double _lastSoundLevel = 0;
  double _minSoundLevel = double.infinity;
  double _maxSoundLevel = double.negativeInfinity;
  int _uncertainRetryCount = 0;
  Timer? _sessionWatchdogTimer;
  Timer? _finalResultGraceTimer;
  String? _lastSpeechError;
  DateTime? _speechSessionStartedAt;
  DateTime? _nativeEndReceivedAt;
  DateTime? _lastResultReceivedAt;

  static const int _maxUncertainRetries = 1;
  static const Duration _minimumRecordingDuration = Duration(milliseconds: 450);
  static const Duration _microphoneReadyTimeout = Duration(seconds: 3);
  static const Duration _maximumSessionDuration = Duration(seconds: 10);
  static const Duration _finalResultGraceDuration = Duration(
    milliseconds: 1500,
  );
  static const Duration _emptyResultGraceDuration = Duration(milliseconds: 500);

  int _speechSessionId = 0;
  bool _hasProcessedCurrentSpeech = false;
  bool _isResultPageOpen = false;
  bool _isStoppingSpeech = false;
  bool _sessionActive = false;
  bool _forceLocalAsrNextAttempt = false;
  bool _localFallbackModeActive = false;

  @override
  void initState() {
    super.initState();

    initSpeech();

    ttsService.preload(widget.word.ttsText).catchError((error) {
      debugPrint('Preload TTS gagal: $error');
    });
  }

  @override
  void dispose() {
    _speechSessionId++;
    _cancelSpeechTimers();
    _sessionActive = false;

    // Jangan detach listener di sini karena SpeechService adalah singleton.
    // Saat pindah ke kata berikutnya dengan pushReplacement, dispose halaman lama
    // bisa terpanggil setelah halaman baru memasang listener. Jika detach tetap
    // dipanggil, listener halaman baru dapat terhapus dan status mic macet di
    // 'Menyiapkan mic...'.
    speechService.cancelListening().catchError((_) {});
    localAsrService.cancel().catchError((_) {});
    ttsService.dispose();

    super.dispose();
  }

  IconData getWordIcon(String category) {
    return AppTheme.getCategoryIcon(category);
  }

  String getIndonesianMeaning(WordModel word) {
    final key = '${word.category.toLowerCase()}|${word.word.toLowerCase()}';

    const translations = <String, String>{
      // Angka
      'angka|zero': 'Nol',
      'angka|one': 'Satu',
      'angka|two': 'Dua',
      'angka|three': 'Tiga',
      'angka|four': 'Empat',
      'angka|five': 'Lima',
      'angka|six': 'Enam',
      'angka|seven': 'Tujuh',
      'angka|eight': 'Delapan',
      'angka|nine': 'Sembilan',

      // Hewan
      'hewan|cat': 'Kucing',
      'hewan|dog': 'Anjing',
      'hewan|bee': 'Lebah',
      'hewan|chicken': 'Ayam',
      'hewan|elephant': 'Gajah',
      'hewan|horse': 'Kuda',
      'hewan|lion': 'Singa',
      'hewan|snake': 'Ular',
      'hewan|rabbit': 'Kelinci',
      'hewan|crocodile': 'Buaya',

      // Buah
      'buah|apple': 'Apel',
      'buah|banana': 'Pisang',
      'buah|orange': 'Jeruk',
      'buah|mango': 'Mangga',
      'buah|grape': 'Anggur',
      'buah|kiwi': 'Kiwi',
      'buah|strawberry': 'Stroberi',
      'buah|guava': 'Jambu',
      'buah|melon': 'Melon',
      'buah|lemon': 'Lemon',
      'buah|pear': 'Pir',
      'buah|peach': 'Persik',

      // Benda
      'benda|book': 'Buku',
      'benda|pen': 'Pulpen',
      'benda|bag': 'Tas',
      'benda|bed': 'Tempat Tidur',
      'benda|cup': 'Cangkir',
      'benda|ball': 'Bola',
      'benda|chair': 'Kursi',
      'benda|table': 'Meja',
      'benda|box': 'Kotak',
      'benda|clock': 'Jam',

      // Warna
      'warna|red': 'Merah',
      'warna|blue': 'Biru',
      'warna|green': 'Hijau',
      'warna|yellow': 'Kuning',
      'warna|black': 'Hitam',
      'warna|white': 'Putih',
      'warna|pink': 'Merah Muda',
      'warna|brown': 'Cokelat',
      'warna|purple': 'Ungu',
      'warna|orange': 'Oranye',

      // Tubuh
      'tubuh|head': 'Kepala',
      'tubuh|hand': 'Tangan',
      'tubuh|foot': 'Telapak Kaki',
      'tubuh|eye': 'Mata',
      'tubuh|ear': 'Telinga',
      'tubuh|nose': 'Hidung',
      'tubuh|mouth': 'Mulut',
      'tubuh|hair': 'Rambut',
      'tubuh|arm': 'Lengan',
      'tubuh|leg': 'Kaki',

      // Makanan
      'makanan|rice': 'Nasi',
      'makanan|bread': 'Roti',
      'makanan|milk': 'Susu',
      'makanan|egg': 'Telur',
      'makanan|cake': 'Kue',
      'makanan|soup': 'Sup',
      'makanan|cheese': 'Keju',
      'makanan|pizza': 'Pizza',
      'makanan|meat': 'Daging',
      'makanan|noodle': 'Mi',

      // Transportasi
      'transportasi|car': 'Mobil',
      'transportasi|bus': 'Bus',
      'transportasi|bike': 'Sepeda',
      'transportasi|train': 'Kereta',
      'transportasi|plane': 'Pesawat',
      'transportasi|boat': 'Perahu',
      'transportasi|truck': 'Truk',
      'transportasi|taxi': 'Taksi',
      'transportasi|ship': 'Kapal',
      'transportasi|motorcycle': 'Sepeda Motor',
    };

    return translations[key] ?? word.word;
  }

  Future<void> playTts() async {
    final word = widget.word;

    if (isLoadingTts ||
        isPreparingSpeech ||
        isListening ||
        isProcessingSpeech ||
        _isStoppingSpeech) {
      return;
    }

    try {
      setState(() {
        isLoadingTts = true;
      });

      await ttsService.speak(word.ttsText);
    } catch (e) {
      if (!mounted) return;

      showTtsWarning(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          isLoadingTts = false;
        });
      }
    }
  }

  Future<void> initSpeech() async {
    final available = await speechService.initialize(
      onStatus: _handleSpeechStatus,
      onError: _handleSpeechError,
    );

    if (!mounted) return;

    setState(() {
      isSpeechAvailable = available;
    });

    debugPrint(
      'Speech available: $available | ASR locale: ${speechService.selectedLocaleId}',
    );
  }

  void _handleSpeechStatus(String status) {
    debugPrint(
      'Speech status: $status | session=$_speechSessionId | active=$_sessionActive',
    );

    if (!mounted || !_sessionActive) return;
    if (_isResultPageOpen || _hasProcessedCurrentSpeech) return;

    final int sessionId = _speechSessionId;

    if (status == 'listening') {
      setState(() {
        isPreparingSpeech = false;
        isListening = true;
        isProcessingSpeech = false;
        micInstruction = 'Silakan ucapkan kata sekarang';
      });

      _enableStopAfterMinimumDuration(sessionId);
      _startSessionWatchdog(sessionId);
      return;
    }

    if (status == 'done' || status == 'notListening') {
      _sessionWatchdogTimer?.cancel();
      _nativeEndReceivedAt ??= DateTime.now();

      debugPrint(
        'ASR native end received | status=$status | session=$sessionId | '
        'time=${_nativeEndReceivedAt!.toIso8601String()} | raw=$recognizedText',
      );

      // Status native inilah yang menjadi sumber kebenaran animasi. Tidak ada
      // lagi penghentian berdasarkan sound level yang berbeda antarperangkat.
      setState(() {
        isPreparingSpeech = false;
        isListening = false;
        isProcessingSpeech = true;
        canStopSpeech = false;
        micInstruction = 'Memproses suara...';
      });

      _scheduleFinalResultGrace(sessionId, source: 'native_$status');
    }
  }

  void _markSpeechAsListeningIfNativeStatusMissing(int sessionId) {
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted || sessionId != _speechSessionId) return;
      if (!_sessionActive || !isPreparingSpeech || _isResultPageOpen) return;

      // Beberapa perangkat mengaktifkan SpeechRecognizer tetapi callback
      // status 'listening' terlambat/tidak sampai setelah pindah halaman.
      // Jika engine native sudah listening, sinkronkan state UI secara manual.
      if (speechService.isListening) {
        debugPrint(
          'ASR listening status recovered manually | session=$sessionId',
        );

        setState(() {
          isPreparingSpeech = false;
          isListening = true;
          isProcessingSpeech = false;
          micInstruction = 'Ayo ucapkan katanya';
        });

        _enableStopAfterMinimumDuration(sessionId);
        _startSessionWatchdog(sessionId);
      }
    });
  }

  void _handleSpeechError(String errorMessage) {
    debugPrint(
      'Speech error: $errorMessage | '
      'session=$_speechSessionId | raw=$recognizedText',
    );

    if (!mounted || !_sessionActive) return;
    if (_isResultPageOpen || _hasProcessedCurrentSpeech) return;

    final normalizedError = errorMessage.toLowerCase();

    final isPermissionError =
        normalizedError.contains('permission') ||
        normalizedError.contains('denied') ||
        normalizedError.contains('not granted');

    if (isPermissionError) {
      _sessionActive = false;
      _cancelSpeechTimers();

      setState(() {
        isPreparingSpeech = false;
        isListening = false;
        isProcessingSpeech = false;
        canStopSpeech = false;
        micInstruction = 'Tekan untuk mulai bicara';
      });

      _showMicrophonePermissionWarning();
      return;
    }

    _lastSpeechError = errorMessage;
    final int sessionId = _speechSessionId;

    _sessionWatchdogTimer?.cancel();

    setState(() {
      isPreparingSpeech = false;
      isListening = false;
      isProcessingSpeech = true;
      canStopSpeech = false;
      micInstruction = 'Memproses suara...';
    });

    _scheduleFinalResultGrace(sessionId, source: 'error_$errorMessage');
  }

  void _cancelSpeechTimers() {
    _sessionWatchdogTimer?.cancel();
    _finalResultGraceTimer?.cancel();
    _sessionWatchdogTimer = null;
    _finalResultGraceTimer = null;
  }

  void _resetSpeechCaptureState() {
    _cancelSpeechTimers();
    _lastSoundLevel = 0;
    _minSoundLevel = double.infinity;
    _maxSoundLevel = double.negativeInfinity;
    _lastSpeechError = null;
    _speechSessionStartedAt = null;
    _nativeEndReceivedAt = null;
    _lastResultReceivedAt = null;
  }

  // ignore: unused_element
  void _setMicIdle({String instruction = 'Tekan untuk mulai bicara'}) {
    if (!mounted) return;

    setState(() {
      isPreparingSpeech = false;
      isListening = false;
      isProcessingSpeech = false;
      canStopSpeech = false;
      micInstruction = instruction;
    });
  }

  void _enableStopAfterMinimumDuration(int sessionId) {
    Future.delayed(_minimumRecordingDuration, () {
      if (!mounted) return;
      if (sessionId != _speechSessionId) return;
      if (!_sessionActive || !isListening || _isResultPageOpen) return;

      setState(() {
        canStopSpeech = true;
        micInstruction = 'Ucapkan kata, lalu diam sebentar';
      });
    });
  }

  void _handleSoundLevel(double level, int sessionId) {
    if (!mounted || sessionId != _speechSessionId) return;
    if (!_sessionActive || !isListening) return;

    // Sound level hanya dipakai untuk diagnostik. Nilainya berbeda-beda pada
    // setiap perangkat sehingga tidak boleh dipakai sebagai pemicu auto-stop.
    _lastSoundLevel = level;
    if (level < _minSoundLevel) _minSoundLevel = level;
    if (level > _maxSoundLevel) _maxSoundLevel = level;
  }

  void _startSessionWatchdog(int sessionId) {
    _sessionWatchdogTimer?.cancel();

    _sessionWatchdogTimer = Timer(_maximumSessionDuration, () async {
      if (!mounted || sessionId != _speechSessionId) return;
      if (!_sessionActive || _hasProcessedCurrentSpeech) return;
      if (_isResultPageOpen || _isStoppingSpeech) return;

      debugPrint('ASR watchdog reached maximum session duration.');
      await _requestNativeStopAndFinalize(
        sessionId,
        reason: 'maximum_duration',
      );
    });
  }

  void _scheduleFinalResultGrace(int sessionId, {required String source}) {
    // Android dapat mengirim done lalu notListening untuk sesi yang sama.
    // Jangan mereset timer karena itu membuat durasi tunggu tidak konsisten.
    if (_finalResultGraceTimer?.isActive ?? false) {
      debugPrint(
        'ASR final grace already active; duplicate source ignored | '
        'source=$source | session=$sessionId',
      );
      return;
    }

    final scheduledAt = DateTime.now();
    final hasCachedResult =
        recognizedText.trim().isNotEmpty ||
        speechService.lastRecognizedWords.trim().isNotEmpty;
    final graceDuration = hasCachedResult
        ? _finalResultGraceDuration
        : _emptyResultGraceDuration;

    debugPrint(
      'ASR final grace scheduled | source=$source | session=$sessionId | '
      'duration=${graceDuration.inMilliseconds}ms | hasCachedResult=$hasCachedResult | '
      'pluginFinalTimeout=${SpeechService.finalResultTimeout.inMilliseconds}ms | '
      'time=${scheduledAt.toIso8601String()}',
    );

    _finalResultGraceTimer = Timer(graceDuration, () async {
      if (!mounted || sessionId != _speechSessionId) return;
      if (!_sessionActive || _hasProcessedCurrentSpeech) return;
      if (_isResultPageOpen) return;

      // Gunakan cache terakhir plugin sebagai fallback jika callback terakhir
      // datang tetapi callback halaman terlambat menerima state.
      if (recognizedText.trim().isEmpty) {
        final cachedWords = speechService.lastRecognizedWords.trim();
        if (cachedWords.isNotEmpty) {
          setState(() {
            recognizedText = cachedWords;
          });
        }
      }

      final endedAt = DateTime.now();
      debugPrint(
        'ASR final grace ended | source=$source | session=$sessionId | '
        'elapsed=${endedAt.difference(scheduledAt).inMilliseconds}ms | '
        'raw=$recognizedText | nativeCache=${speechService.lastRecognizedWords} | '
        'time=${endedAt.toIso8601String()}',
      );

      if (recognizedText.trim().isNotEmpty) {
        _sessionActive = false;
        _isStoppingSpeech = false;
        await processSpeechResult(sessionId);
        return;
      }

      _showNoResultWarning(sessionId, source: source);
    });
  }

  void _showNoResultWarning(int sessionId, {required String source}) {
    if (!mounted || sessionId != _speechSessionId) return;

    _sessionActive = false;
    _isStoppingSpeech = false;
    _cancelSpeechTimers();
    _forceLocalAsrNextAttempt = true;
    _localFallbackModeActive = false;

    setState(() {
      isPreparingSpeech = false;
      isListening = false;
      isProcessingSpeech = false;
      canStopSpeech = false;
      micInstruction = 'Tekan untuk mulai bicara';
    });

    debugPrint('=== ASR EMPTY RESULT ===');
    debugPrint('Target          : ${widget.word.word}');
    debugPrint('Category        : ${widget.word.category}');
    debugPrint('Locale          : ${speechService.selectedLocaleId}');
    debugPrint('Source          : $source');
    debugPrint('Last error      : $_lastSpeechError');
    debugPrint('Native status   : ${speechService.lastStatus}');
    debugPrint('Native cache    : ${speechService.lastRecognizedWords}');
    debugPrint(
      'Session started : ${_speechSessionStartedAt?.toIso8601String()}',
    );
    debugPrint('Native ended    : ${_nativeEndReceivedAt?.toIso8601String()}');
    debugPrint('Last result at  : ${_lastResultReceivedAt?.toIso8601String()}');
    debugPrint('Warning time    : ${DateTime.now().toIso8601String()}');
    debugPrint(
      'Grace duration  : ${_finalResultGraceDuration.inMilliseconds} ms',
    );
    debugPrint(
      'Final timeout   : ${SpeechService.finalResultTimeout.inMilliseconds} ms',
    );
    debugPrint('Last sound level: $_lastSoundLevel');
    debugPrint('Min/Max level   : $_minSoundLevel / $_maxSoundLevel');
    debugPrint('========================');

    debugPrint(
      'Sequential ASR fallback prepared: next mic tap will use Local ASR.',
    );

    _showPracticeSnackBar(
      type: LearningMessageType.warning,
      message: 'Suara belum jelas. Coba lagi ya.',
    );
  }

  bool _isMicrophonePermissionError(Object error) {
    final message = error.toString().toLowerCase();

    return message.contains('permission') ||
        message.contains('izin mikrofon') ||
        message.contains('not granted') ||
        message.contains('denied');
  }

  void _showMicrophonePermissionWarning() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Izin Mikrofon Diperlukan'),
          content: const Text(
            'Aplikasi memerlukan izin mikrofon untuk merekam suara. '
            'Aktifkan izin mikrofon pada pengaturan aplikasi, lalu coba lagi.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Nanti'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings(); // membuka halaman pengaturan izin aplikasi
              },
              child: const Text('Buka Pengaturan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> startSpeechRecognition() async {
    if (_isResultPageOpen ||
        isProcessingSpeech ||
        isListening ||
        isPreparingSpeech ||
        _sessionActive) {
      return;
    }

    if (_forceLocalAsrNextAttempt) {
      _forceLocalAsrNextAttempt = false;
      debugPrint(
        'Sequential ASR fallback activated: starting Local ASR after Google ASR empty result.',
      );
      await startLocalAsrPractice();
      return;
    }

    if (!isSpeechAvailable) {
      debugPrint('Google ASR unavailable: starting Local ASR fallback.');
      await startLocalAsrPractice();
      return;
    }

    final int sessionId = ++_speechSessionId;

    _hasProcessedCurrentSpeech = false;
    _isStoppingSpeech = false;
    _sessionActive = true;
    _resetSpeechCaptureState();
    _speechSessionStartedAt = DateTime.now();

    setState(() {
      recognizedText = '';
      _lastAsrConfidence = -1;
      isPreparingSpeech = true;
      isListening = false;
      isProcessingSpeech = false;
      canStopSpeech = false;
      micInstruction = 'Menyiapkan mic...';
    });

    debugPrint(
      'ASR session started | method=Google ASR | session=$sessionId | target=${widget.word.word} | '
      'time=${_speechSessionStartedAt!.toIso8601String()}',
    );

    try {
      await ttsService.stop();

      // Pastikan audio focus dari TTS dan sesi ASR lama benar-benar dilepas.
      await speechService.cancelListening();
      await Future.delayed(const Duration(milliseconds: 160));

      if (!mounted || sessionId != _speechSessionId || !_sessionActive) return;

      Future.delayed(_microphoneReadyTimeout, () async {
        if (!mounted || sessionId != _speechSessionId) return;
        if (!_sessionActive || !isPreparingSpeech || isListening) return;

        _sessionActive = false;
        await speechService.cancelListening();
        if (!mounted || sessionId != _speechSessionId) return;

        setState(() {
          isPreparingSpeech = false;
          isListening = false;
          isProcessingSpeech = false;
          canStopSpeech = false;
          micInstruction = 'Tekan untuk mulai bicara';
        });

        _showPracticeSnackBar(
          type: LearningMessageType.warning,
          message: 'Mic belum siap. Coba tekan lagi ya.',
        );
      });

      await speechService.startListening(
        onSoundLevelChange: (level) => _handleSoundLevel(level, sessionId),
        onResult: (result) {
          if (!mounted || sessionId != _speechSessionId) return;
          if (!_sessionActive || _isResultPageOpen) return;
          if (_hasProcessedCurrentSpeech) return;

          final resultWords = result.words.trim();
          _lastResultReceivedAt = DateTime.now();

          // Jangan menimpa hasil non-kosong dengan callback parsial kosong.
          if (resultWords.isNotEmpty) {
            setState(() {
              recognizedText = resultWords;
              _lastAsrConfidence = result.confidence;
            });
          }

          debugPrint(
            'ASR partial/final result | target=${widget.word.word} | '
            'locale=${speechService.selectedLocaleId} | raw=${result.words} | '
            'final=${result.isFinal} | confidence=${result.confidence} | '
            'time=${_lastResultReceivedAt!.toIso8601String()}',
          );

          if (result.isFinal && resultWords.isNotEmpty) {
            _sessionActive = false;
            _isStoppingSpeech = false;
            _cancelSpeechTimers();
            processSpeechResult(sessionId);
          }
        },
      );

      _markSpeechAsListeningIfNativeStatusMissing(sessionId);
    } catch (error) {
      debugPrint('Google ASR gagal dimulai: $error');

      if (!mounted) return;

      _sessionActive = false;
      _cancelSpeechTimers();

      setState(() {
        isPreparingSpeech = false;
        isListening = false;
        isProcessingSpeech = false;
        canStopSpeech = false;
        micInstruction = 'Tekan untuk mulai bicara';
      });

      if (_isMicrophonePermissionError(error)) {
        _showMicrophonePermissionWarning();
        return;
      }

      _showPracticeSnackBar(
        type: LearningMessageType.error,
        message: 'Mikrofon belum dapat digunakan. Coba lagi ya.',
      );
    }
  }

  Future<void> stopSpeechRecognition() async {
    if (_isResultPageOpen || isProcessingSpeech || !_sessionActive) {
      return;
    }

    if (isPreparingSpeech) {
      _showPracticeSnackBar(
        type: LearningMessageType.warning,
        message: 'Tunggu mic siap dulu ya.',
        duration: const Duration(milliseconds: 1800),
      );
      return;
    }

    if (!canStopSpeech) {
      _showPracticeSnackBar(
        type: LearningMessageType.warning,
        message: 'Ucapkan 1 kata dulu ya.',
        duration: const Duration(milliseconds: 1800),
      );
      return;
    }

    await _requestNativeStopAndFinalize(
      _speechSessionId,
      reason: 'manual_stop',
    );
  }

  Future<void> startLocalAsrPractice() async {
    if (isListening ||
        isProcessingSpeech ||
        isLoadingTts ||
        isPreparingSpeech) {
      return;
    }

    _cancelSpeechTimers();
    _sessionActive = false;
    _isStoppingSpeech = false;
    _localFallbackModeActive = true;

    setState(() {
      isPreparingSpeech = true;
      isListening = false;
      isProcessingSpeech = false;
      canStopSpeech = false;
      recognizedText = '';
      micInstruction = 'Menyiapkan mic...';
    });

    try {
      await ttsService.stop();
      await speechService.cancelListening();
      await localAsrService.cancel().catchError((_) {});
      await Future.delayed(const Duration(milliseconds: 120));

      if (!mounted) return;

      setState(() {
        isPreparingSpeech = false;
        isListening = true;
        isProcessingSpeech = false;
        canStopSpeech = true;
        micInstruction = 'Ucapkan kata, lalu tekan stop';
      });

      await localAsrService.startRecording();
      debugPrint('Sequential ASR: local ASR fallback recording started.');
    } catch (error) {
      debugPrint('Start Local ASR gagal: $error');

      if (!mounted) return;

      _localFallbackModeActive = false;

      setState(() {
        isPreparingSpeech = false;
        isListening = false;
        isProcessingSpeech = false;
        canStopSpeech = false;
        micInstruction = 'Tekan untuk mulai bicara';
      });

      if (_isMicrophonePermissionError(error)) {
        _showMicrophonePermissionWarning();
        return;
      }

      _showPracticeSnackBar(
        type: LearningMessageType.warning,
        message: 'Mikrofon belum dapat digunakan. Coba lagi ya.',
      );
    }
  }

  Future<void> stopLocalAsrPractice() async {
    if (!isListening || isProcessingSpeech) {
      return;
    }

    try {
      setState(() {
        isListening = false;
        isProcessingSpeech = true;
        canStopSpeech = false;
        micInstruction = 'Memproses suara...';
      });

      final result = await localAsrService.stopAndPredict();

      if (!mounted) return;

      final targetLabel = widget.word.word.toLowerCase().trim();
      final predictedLabel = result.label.toLowerCase().trim();

      if (!localAsrService.isAcceptedPrediction(result)) {
        debugPrint('LOCAL ASR REJECTED');
        debugPrint('Label      : ${result.label}');
        debugPrint('Confidence : ${result.confidence}');

        _localFallbackModeActive = false;

        setState(() {
          isListening = false;
          isProcessingSpeech = false;
          canStopSpeech = false;
          recognizedText = '';
          micInstruction = 'Tekan untuk mulai bicara';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Suara belum jelas. Coba lagi ya.')),
        );

        return;
      }

      final normalizedTarget = LevenshteinService.normalizeText(targetLabel);
      final normalizedPrediction = LevenshteinService.normalizeText(
        predictedLabel,
      );

      final distance = LevenshteinService.calculateDistance(
        targetLabel,
        predictedLabel,
      );

      final maxLength = normalizedTarget.length > normalizedPrediction.length
          ? normalizedTarget.length
          : normalizedPrediction.length;

      final rawScore = maxLength == 0
          ? 0.0
          : (1 - (distance / maxLength)) * 100;

      final score = LevenshteinService.calculateScore(
        targetLabel,
        predictedLabel,
      );

      final feedback = LevenshteinService.getFeedback(score);

      debugPrint('=== LOCAL ASR DIAGNOSTIC ===');
      debugPrint('Target raw        : $targetLabel');
      debugPrint('Prediction raw    : $predictedLabel');
      debugPrint('Target normalized : $normalizedTarget');
      debugPrint('Result normalized : $normalizedPrediction');
      debugPrint('Confidence        : ${result.confidence}');
      debugPrint('Distance          : $distance');
      debugPrint('Max length        : $maxLength');
      debugPrint('Score formula     : (1 - ($distance / $maxLength)) x 100');
      debugPrint('Score raw         : ${rawScore.toStringAsFixed(2)}');
      debugPrint('Score final       : $score');
      debugPrint('Feedback          : $feedback');
      debugPrint('ASR method        : Local ASR');
      debugPrint('============================');

      try {
        await DatabaseService.instance.insertPracticeResult(
          PracticeResult(
            word: widget.word.word,
            category: widget.word.category,
            recognizedWord: predictedLabel,
            distance: distance,
            score: score,
            feedback: feedback,
            asrMethod: 'Local ASR',
            createdAt: DateTime.now().toIso8601String(),
          ),
        );

        await PerfectScoreNotifier.refresh();
        debugPrint(
          'RECENT PRACTICE SAVED | method=Local ASR | target=${widget.word.word} | '
          'detected=$predictedLabel | score=$score | category=${widget.word.category}',
        );
      } catch (error) {
        debugPrint('Gagal menyimpan hasil latihan lokal ASR: $error');
      }

      if (!mounted) return;

      final action = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            targetWord: widget.word.word,
            recognizedWord: predictedLabel,
            distance: distance,
            score: score.toDouble(),
            feedback: feedback,
          ),
        ),
      );

      if (!mounted) return;

      _localFallbackModeActive = false;

      setState(() {
        isListening = false;
        isProcessingSpeech = false;
        canStopSpeech = false;
        recognizedText = '';
        micInstruction = 'Tekan untuk mulai bicara';
      });

      if (action == 'next') {
        goToNextWord();
      }
    } catch (error) {
      debugPrint('Stop local ASR gagal: $error');

      if (!mounted) return;

      _localFallbackModeActive = false;

      setState(() {
        isListening = false;
        isProcessingSpeech = false;
        canStopSpeech = false;
        recognizedText = '';
        micInstruction = 'Tekan untuk mulai bicara';
      });

      _showPracticeSnackBar(
        type: LearningMessageType.warning,
        message: 'Suara belum berhasil diproses. Coba lagi ya.',
      );
    }
  }

  Future<void> _requestNativeStopAndFinalize(
    int sessionId, {
    required String reason,
  }) async {
    if (!mounted || sessionId != _speechSessionId) return;
    if (!_sessionActive || _hasProcessedCurrentSpeech) return;
    if (_isResultPageOpen || _isStoppingSpeech) return;

    _isStoppingSpeech = true;
    _sessionWatchdogTimer?.cancel();

    setState(() {
      isPreparingSpeech = false;
      isListening = false;
      isProcessingSpeech = true;
      canStopSpeech = false;
      micInstruction = 'Memproses suara...';
    });

    await speechService.stopListening();

    if (!mounted || sessionId != _speechSessionId) return;

    _scheduleFinalResultGrace(sessionId, source: reason);
  }

  Future<void> processSpeechResult([int? sessionId]) async {
    if (_isResultPageOpen) return;
    if (_hasProcessedCurrentSpeech) return;

    if (sessionId != null && sessionId != _speechSessionId) {
      return;
    }

    final word = widget.word;
    final rawResult = recognizedText.trim();

    if (rawResult.isEmpty) {
      setState(() {
        isProcessingSpeech = false;
        isPreparingSpeech = false;
        isListening = false;
        canStopSpeech = false;
        micInstruction = 'Tekan untuk mulai bicara';
      });

      _showPracticeSnackBar(
        type: LearningMessageType.warning,
        message: 'Suara belum terbaca. Coba lagi ya.',
      );

      return;
    }

    _hasProcessedCurrentSpeech = true;
    _cancelSpeechTimers();
    _sessionActive = false;
    _isStoppingSpeech = false;

    // Naikkan session id supaya callback speech lama otomatis dianggap basi.
    _speechSessionId++;

    setState(() {
      isProcessingSpeech = true;
      isPreparingSpeech = false;
      isListening = false;
      canStopSpeech = false;
      micInstruction = 'Tekan untuk mulai bicara';
    });

    final decision = AsrTextProcessor.evaluateCandidateQuality(
      targetWord: word.word,
      recognizedText: rawResult,
      confidence: _lastAsrConfidence,
    );

    final result = decision.candidate;

    if (result.isEmpty) {
      setState(() {
        isProcessingSpeech = false;
        isPreparingSpeech = false;
      });

      _showPracticeSnackBar(
        type: LearningMessageType.warning,
        message: 'Suara belum terbaca. Coba lagi ya.',
      );
      return;
    }

    if (decision.shouldRetry && _uncertainRetryCount < _maxUncertainRetries) {
      _uncertainRetryCount++;
      _hasProcessedCurrentSpeech = false;
      final double confidenceForLog = _lastAsrConfidence;

      setState(() {
        isProcessingSpeech = false;
        isPreparingSpeech = false;
        isListening = false;
        canStopSpeech = false;
        recognizedText = '';
        _lastAsrConfidence = -1;
        micInstruction = 'Tekan untuk mulai bicara';
      });

      final retryTarget = LevenshteinService.normalizeText(word.word);
      final retryCandidate = LevenshteinService.normalizeText(result);

      final retryMaxLength = retryTarget.length > retryCandidate.length
          ? retryTarget.length
          : retryCandidate.length;

      debugPrint('=== ASR RETRY GATE ===');
      debugPrint('Target raw        : ${word.word}');
      debugPrint('Category          : ${word.category}');
      debugPrint('Raw ASR           : $rawResult');
      debugPrint('Clean Candidate   : $result');
      debugPrint('Target normalized : $retryTarget');
      debugPrint('Result normalized : $retryCandidate');
      debugPrint('Confidence        : $confidenceForLog');
      debugPrint('Distance          : ${decision.distance}');
      debugPrint('Max length        : $retryMaxLength');
      debugPrint('Score final       : ${decision.score}');
      debugPrint('Retry count       : $_uncertainRetryCount');
      debugPrint('Reason            : ${decision.retryMessage}');
      debugPrint('======================');

      _showPracticeSnackBar(
        type: LearningMessageType.warning,
        message: 'Coba ucapkan lagi dengan jelas ya.',
        duration: const Duration(milliseconds: 2600),
      );
      return;
    }

    _uncertainRetryCount = 0;

    final int distance = decision.distance;
    final int score = decision.score;

    final normalizedTarget = LevenshteinService.normalizeText(word.word);
    final normalizedCandidate = LevenshteinService.normalizeText(result);

    final maxLength = normalizedTarget.length > normalizedCandidate.length
        ? normalizedTarget.length
        : normalizedCandidate.length;

    final rawScore = maxLength == 0 ? 0.0 : (1 - (distance / maxLength)) * 100;

    debugPrint('=== ASR DIAGNOSTIC ===');
    debugPrint('Target raw        : ${word.word}');
    debugPrint('Category          : ${word.category}');
    debugPrint('ASR Locale        : ${speechService.selectedLocaleId}');
    debugPrint('Raw ASR           : $rawResult');
    debugPrint('Clean Candidate   : $result');
    debugPrint('Target normalized : $normalizedTarget');
    debugPrint('Result normalized : $normalizedCandidate');
    debugPrint('Confidence        : $_lastAsrConfidence');
    debugPrint('Distance          : $distance');
    debugPrint('Max length        : $maxLength');
    debugPrint('Score formula     : (1 - ($distance / $maxLength)) x 100');
    debugPrint('Score raw         : ${rawScore.toStringAsFixed(2)}');
    debugPrint('Score final       : $score');
    debugPrint('ASR method        : Google ASR');
    debugPrint('======================');

    final String feedback = LevenshteinService.getFeedback(score);
    try {
      await DatabaseService.instance.insertPracticeResult(
        PracticeResult(
          word: word.word,
          category: word.category,
          recognizedWord: result,
          distance: distance,
          score: score,
          feedback: feedback,
          asrMethod: 'Google ASR',
          createdAt: DateTime.now().toIso8601String(),
        ),
      );
      await PerfectScoreNotifier.refresh();
      debugPrint(
        'RECENT PRACTICE SAVED | method=Google ASR | target=${word.word} | '
        'detected=$result | score=$score | distance=$distance | category=${word.category}',
      );
    } catch (e) {
      debugPrint('Gagal menyimpan hasil latihan: $e');
    }

    if (!mounted) return;

    _isResultPageOpen = true;

    final action = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          targetWord: word.word,
          recognizedWord: result,
          distance: distance,
          score: score.toDouble(),
          feedback: feedback,
        ),
      ),
    );

    if (!mounted) return;

    _isResultPageOpen = false;

    // Naikkan lagi session id agar callback lama dari halaman result tidak bisa
    // memproses ulang saat user menekan Play Again.
    _speechSessionId++;

    setState(() {
      isProcessingSpeech = false;
      isPreparingSpeech = false;
      isListening = false;
      canStopSpeech = false;
      recognizedText = '';
      _lastAsrConfidence = -1;
      _uncertainRetryCount = 0;
      _lastSoundLevel = 0;
      _minSoundLevel = double.infinity;
      _maxSoundLevel = double.negativeInfinity;
      _sessionActive = false;
      _forceLocalAsrNextAttempt = false;
      _localFallbackModeActive = false;
      micInstruction = 'Tekan untuk mulai bicara';
    });

    if (action == 'next') {
      goToNextWord();
    }
  }

  void _showPracticeSnackBar({
    required String message,
    LearningMessageType type = LearningMessageType.warning,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!mounted) return;

    // Semua peringatan rekaman/ASR dibuat pendek dan child-friendly.
    // Pesan teknis seperti Google ASR, fallback, timeout, atau jaringan
    // tetap dicatat di debugPrint, tetapi tidak ditampilkan ke anak.
    const simpleChildWarning = 'Suara belum jelas. Coba lagi ya.';
    final displayMessage =
        type == LearningMessageType.warning || type == LearningMessageType.error
        ? simpleChildWarning
        : message;

    showLearningSnackBar(
      context: context,
      type: type,
      message: displayMessage,
      duration: duration,
      bottomMargin: 148,
    );
  }

  void showTtsWarning(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('TTS Tidak Tersedia'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Mengerti'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                playTts();
              },
              child: const Text('Coba Lagi'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _prepareForWordTransition() async {
    _cancelSpeechTimers();
    _sessionActive = false;
    _isStoppingSpeech = false;
    _forceLocalAsrNextAttempt = false;
    _localFallbackModeActive = false;

    await ttsService.stop().catchError((_) {});
    await speechService.cancelListening().catchError((_) {});
    await localAsrService.cancel().catchError((_) {});

    if (!mounted) return;

    setState(() {
      isPreparingSpeech = false;
      isListening = false;
      isProcessingSpeech = false;
      canStopSpeech = false;
      recognizedText = '';
      micInstruction = 'Tekan mic dulu';
    });
  }

  Future<void> goToNextWord() async {
    final words = widget.words;

    if (words == null || words.isEmpty) {
      await _prepareForWordTransition();
      if (!mounted) return;
      Navigator.pop(context);
      return;
    }

    final nextIndex = widget.currentIndex + 1;

    if (nextIndex >= words.length) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text(
              'Great Job!',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: AppTheme.darkText,
              ),
            ),
            content: const Text(
              'Kamu sudah menyelesaikan semua kata pada kategori ini.',
              style: TextStyle(color: AppTheme.mutedText, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // tutup dialog
                  Navigator.pop(context); // kembali ke WordListScreen
                },
                child: const Text(
                  'Kembali',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.goldDark,
                  ),
                ),
              ),
            ],
          );
        },
      );
      return;
    }

    final nextWord = words[nextIndex];

    await _prepareForWordTransition();
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PracticeScreen(
          word: nextWord,
          words: words,
          currentIndex: nextIndex,
        ),
      ),
    );
  }

  //
  Widget _buildTopHeader() {
    return LearningHeader(
      title: 'LingoJoy',
      showBackButton: true,
      onBack: () async {
        await _prepareForWordTransition();

        if (!mounted) return;

        Navigator.pop(context);
      },
    );
  }

  Widget _buildListenButton() {
    final bool isDisabled =
        isPreparingSpeech ||
        isListening ||
        isProcessingSpeech ||
        _isStoppingSpeech;

    return IgnorePointer(
      ignoring: isDisabled,
      child: AnimatedOpacity(
        opacity: isDisabled ? 0.55 : 1,
        duration: const Duration(milliseconds: 180),
        child: GestureDetector(
          onTap: isLoadingTts ? null : playTts,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.softBlue,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.softBlue.withValues(alpha: 0.55),
                  blurRadius: 0,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.volume_up_rounded,
                    color: AppTheme.darkText,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isLoadingTts ? 'Memutar suara...' : 'Dengar Contoh',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.darkText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Tekan dulu sebelum bicara',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.play_arrow_rounded,
                  color: AppTheme.darkText,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWordCard() {
    final word = widget.word;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 360;

        // Pada viewport pendek (misalnya Chrome berbentuk kotak), susunan
        // gambar + label dibuat horizontal. Dengan begitu label tidak lagi
        // memaksa tinggi kartu dan memicu RenderFlex overflow.
        final bool useHorizontalLayout = availableHeight < 185;
        final bool compact = availableHeight < 270;

        final double outerPadding = useHorizontalLayout
            ? 7
            : (compact ? 10 : 16);
        final double imagePadding = useHorizontalLayout
            ? 5
            : (compact ? 8 : 14);
        final double gap = useHorizontalLayout ? 8 : (compact ? 8 : 12);
        final double labelPaddingH = useHorizontalLayout
            ? 12
            : (compact ? 20 : 28);
        final double labelPaddingV = useHorizontalLayout
            ? 5
            : (compact ? 7 : 10);
        final double wordFontSize = useHorizontalLayout
            ? 28
            : (compact ? 30 : 34);
        final double meaningFontSize = useHorizontalLayout
            ? 11
            : (compact ? 12 : 13);

        final imagePanel = Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(useHorizontalLayout ? 22 : 28),
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(imagePadding),
              child: Image.asset(
                'assets/images/words/${word.imageName}',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) {
                  return Icon(
                    Icons.image_not_supported_rounded,
                    size: useHorizontalLayout ? 54 : 90,
                    color: AppTheme.mutedText,
                  );
                },
              ),
            ),
          ),
        );

        final labelPanel = Container(
          width: double.infinity,
          height: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: labelPaddingH,
            vertical: labelPaddingV,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(useHorizontalLayout ? 22 : 28),
            border: Border.all(
              color: AppTheme.gold.withOpacity(0.28),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  word.word.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: wordFontSize,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: AppTheme.goldDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  getIndonesianMeaning(word),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: meaningFontSize,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.mutedText,
                  ),
                ),
              ],
            ),
          ),
        );

        Widget content;

        if (useHorizontalLayout) {
          content = Row(
            children: [
              Expanded(flex: 3, child: imagePanel),
              SizedBox(width: gap),
              Expanded(flex: 2, child: labelPanel),
            ],
          );
        } else {
          final double calculatedLabelHeight = availableHeight * 0.27;
          final double labelHeight = calculatedLabelHeight < 58
              ? 58
              : (calculatedLabelHeight > 78 ? 78 : calculatedLabelHeight);

          content = Column(
            children: [
              Expanded(child: imagePanel),
              SizedBox(height: gap),
              SizedBox(height: labelHeight, child: labelPanel),
            ],
          );
        }

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(outerPadding),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F4F0),
            borderRadius: BorderRadius.circular(useHorizontalLayout ? 28 : 36),
            border: Border.all(
              color: Colors.white,
              width: useHorizontalLayout ? 4 : (compact ? 5 : 6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: content,
        );
      },
    );
  }

  Widget _buildWaveBars() {
    final bars = [
      {'height': 18.0, 'color': const Color(0xFF2E7D32)},
      {'height': 31.0, 'color': const Color(0xFFEF6C00)},
      {'height': 23.0, 'color': const Color(0xFF1565C0)},
      {'height': 36.0, 'color': const Color(0xFF2E7D32)},
      {'height': 22.0, 'color': const Color(0xFFEF6C00)},
      {'height': 29.0, 'color': const Color(0xFF1565C0)},
      {'height': 17.0, 'color': const Color(0xFF2E7D32)},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: bars.map((bar) {
        return Container(
          width: 5,
          height: bar['height'] as double,
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          decoration: BoxDecoration(
            color: bar['color'] as Color,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMicButton() {
    final bool isStopLocked = isListening && !canStopSpeech;
    final bool isDisabled =
        isPreparingSpeech ||
        isProcessingSpeech ||
        _isStoppingSpeech ||
        isStopLocked;

    final bool isActive = isListening || _sessionActive;

    return GestureDetector(
      onTap: isDisabled
          ? null
          : () {
              if (_localFallbackModeActive && isListening) {
                stopLocalAsrPractice();
              } else if (isListening || _sessionActive) {
                stopSpeechRecognition();
              } else {
                startSpeechRecognition();
              }
            },
      child: AnimatedOpacity(
        opacity: isDisabled ? 0.55 : 1,
        duration: const Duration(milliseconds: 180),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: isActive ? 164 : 152,
              height: isActive ? 164 : 152,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? const Color(0xFFFFE0CC)
                    : const Color(0xFFFFF2E8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD84315).withValues(alpha: 0.18),
                    blurRadius: 26,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: isActive ? 118 : 110,
                  height: isActive ? 118 : 110,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFEF6C00)
                        : const Color(0xFFD84315),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF962B07).withValues(alpha: 0.55),
                        blurRadius: 0,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    isActive ? Icons.stop_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 56,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Text(
                isActive ? 'TEKAN UNTUK STOP' : 'TEKAN MIC',
                style: TextStyle(
                  fontSize: isActive ? 15 : 17,
                  fontWeight: FontWeight.w900,
                  color: isActive
                      ? const Color(0xFFEF6C00)
                      : const Color(0xFFD84315),
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListeningChip() {
    if (!isListening) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.gold,
            ),
          ),
          SizedBox(width: 8),
          Text(
            'Sedang mendengar...',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppTheme.goldDark,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final word = widget.word;

    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          child: Column(
            children: [
              _buildTopHeader(),

              const SizedBox(height: 12),

              _buildListenButton(),

              const SizedBox(height: 14),

              Expanded(
                child: Column(
                  children: [
                    Expanded(flex: 7, child: _buildWordCard()),

                    const SizedBox(height: 8),

                    _buildWaveBars(),

                    const SizedBox(height: 8),

                    Text(
                      'Ucapkan "${word.word.toUpperCase()}"!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.darkText,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      micInstruction,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.mutedText,
                        height: 1.35,
                      ),
                    ),

                    const SizedBox(height: 12),

                    _buildMicButton(),

                    const SizedBox(height: 10),

                    _buildListeningChip(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
