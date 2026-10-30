import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class LingoJoyAudioRecorderService {
  LingoJoyAudioRecorderService._internal();

  static final LingoJoyAudioRecorderService instance =
      LingoJoyAudioRecorderService._internal();

  final AudioRecorder _recorder = AudioRecorder();

  String? _currentPath;

  Future<bool> hasPermission() async {
    return _recorder.hasPermission();
  }

  Future<String> startRecording() async {
    final hasMicPermission = await _recorder.hasPermission();

    if (!hasMicPermission) {
      throw StateError('Izin mikrofon belum diberikan.');
    }

    final tempDir = await getTemporaryDirectory();

    final fileName =
        'lingojoy_record_${DateTime.now().millisecondsSinceEpoch}.wav';

    final filePath = '${tempDir.path}/$fileName';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
        autoGain: false,
        echoCancel: false,
        noiseSuppress: false,
      ),
      path: filePath,
    );

    _currentPath = filePath;

    debugPrint('LINGOJOY RECORD STARTED');
    debugPrint('Path: $filePath');

    return filePath;
  }

  Future<String?> stopRecording() async {
    final path = await _recorder.stop();

    if (path == null) {
      debugPrint('LINGOJOY RECORD STOPPED: path null');
      return null;
    }

    final file = File(path);

    debugPrint('LINGOJOY RECORD STOPPED');
    debugPrint('Path  : $path');
    debugPrint('Exists: ${file.existsSync()}');
    debugPrint('Size  : ${file.existsSync() ? file.lengthSync() : 0} bytes');

    _currentPath = null;

    return path;
  }

  Future<bool> isRecording() {
    return _recorder.isRecording();
  }

  Future<void> cancelRecording() async {
    await _recorder.cancel();
    _currentPath = null;
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }

  String? get currentPath => _currentPath;
}
