import 'package:flutter/foundation.dart';

import 'lingojoy_audio_recorder_service.dart';
import 'lingojoy_wav_reader_service.dart';
import 'lingojoy_mfcc_extractor_service.dart';
import 'lingojoy_asr_model_service.dart';

class LingoJoyLocalAsrResult {
  final String label;
  final double confidence;
  final String wavPath;
  final double audioDuration;
  final int mfccFrames;

  const LingoJoyLocalAsrResult({
    required this.label,
    required this.confidence,
    required this.wavPath,
    required this.audioDuration,
    required this.mfccFrames,
  });

  bool get isRejectedLabel {
    return label == 'noise' || label == 'unknown' || label == 'silence';
  }
}

class LingoJoyLocalAsrService {
  LingoJoyLocalAsrService._internal();

  static final LingoJoyLocalAsrService instance =
      LingoJoyLocalAsrService._internal();

  static const double confidenceThreshold = 0.40;

  final _recorder = LingoJoyAudioRecorderService.instance;
  final _wavReader = LingoJoyWavReaderService.instance;
  final _mfccExtractor = LingoJoyMfccExtractorService.instance;
  final _model = LingoJoyAsrModelService.instance;

  Future<bool> hasPermission() {
    return _recorder.hasPermission();
  }

  Future<void> initialize() async {
    await _model.initialize();
    await _mfccExtractor.initialize();
  }

  Future<void> startRecording() async {
    await initialize();

    final hasMicPermission = await _recorder.hasPermission();

    if (!hasMicPermission) {
      throw StateError('Izin mikrofon belum diberikan.');
    }

    await _recorder.startRecording();
  }

  Future<LingoJoyLocalAsrResult> stopAndPredict() async {
    final recordedPath = await _recorder.stopRecording();

    if (recordedPath == null) {
      throw StateError('File rekaman tidak tersedia.');
    }

    final wavData = await _wavReader.readWavFile(recordedPath);

    if (wavData.sampleRate != LingoJoyMfccExtractorService.sampleRate) {
      throw StateError(
        'Sample rate rekaman harus ' 
        '${LingoJoyMfccExtractorService.sampleRate} Hz, ' 
        'tetapi ditemukan ${wavData.sampleRate} Hz.',
      );
    }

    final trimmedSamples = _mfccExtractor.trimSilence(
      wavData.samples,
      topDb: 35.0,
      frameLength: 512,
      trimHopLength: 160,
      paddingSamples: 2400,
    );

    if (trimmedSamples.isEmpty) {
      throw StateError('Audio kosong setelah proses trim silence.');
    }

    final mfcc = await _mfccExtractor.extractNormalizedMfcc(trimmedSamples);

    final prediction = await _model.predictFromMfcc(mfcc);

    debugPrint('=== LINGOJOY LOCAL ASR RESULT ===');
    debugPrint('WAV path     : $recordedPath');
    debugPrint('Duration     : ${wavData.durationSeconds}');
    debugPrint('Trim samples : ${trimmedSamples.length}');
    debugPrint('Trim duration: ' 
        '${trimmedSamples.length / wavData.sampleRate} seconds');
    debugPrint('MFCC frames  : ${mfcc.length}');
    debugPrint('Label        : ${prediction.label}');
    debugPrint('Confidence   : ${prediction.confidence}');
    debugPrint('=================================');

    return LingoJoyLocalAsrResult(
      label: prediction.label,
      confidence: prediction.confidence,
      wavPath: recordedPath,
      audioDuration: wavData.durationSeconds,
      mfccFrames: mfcc.length,
    );
  }

  Future<void> cancel() async {
    await _recorder.cancelRecording();
  }

  bool isAcceptedPrediction(LingoJoyLocalAsrResult result) {
    if (result.confidence < confidenceThreshold) {
      return false;
    }

    if (result.isRejectedLabel) {
      return false;
    }

    return true;
  }
}
