import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class LingoJoyPrediction {
  final String label;
  final double confidence;
  final int index;

  const LingoJoyPrediction({
    required this.label,
    required this.confidence,
    required this.index,
  });
}

class LingoJoyAsrModelService {
  LingoJoyAsrModelService._internal();

  static final LingoJoyAsrModelService instance =
      LingoJoyAsrModelService._internal();

  static const int fixedFrames = 500;
  static const int mfccCount = 40;

  Interpreter? _interpreter;
  List<String> _labels = [];

  bool get isLoaded => _interpreter != null && _labels.isNotEmpty;
  List<String> get labels => List.unmodifiable(_labels);

  Future<void> initialize() async {
    if (isLoaded) return;

    final labelsText = await rootBundle.loadString('assets/asr/labels.txt');

    _labels = labelsText
        .split('\n')
        .map((label) => label.trim())
        .where((label) => label.isNotEmpty)
        .toList();

    _interpreter = await Interpreter.fromAsset(
      'assets/asr/lingojoy_asr_float32.tflite',
    );

    _interpreter!.allocateTensors();

    debugPrint('LINGOJOY ASR MODEL LOADED');
    debugPrint('Labels      : ${_labels.length}');
    debugPrint('Input shape : ${_interpreter!.getInputTensor(0).shape}');
    debugPrint('Output shape: ${_interpreter!.getOutputTensor(0).shape}');
  }

  List<List<double>> _padOrTruncateMfcc(List<List<double>> mfcc) {
    final result = List.generate(
      fixedFrames,
      (_) => List<double>.filled(mfccCount, 0.0),
    );

    final copyFrames = min(mfcc.length, fixedFrames);

    for (int frameIndex = 0; frameIndex < copyFrames; frameIndex++) {
      for (int mfccIndex = 0; mfccIndex < mfccCount; mfccIndex++) {
        result[frameIndex][mfccIndex] = mfcc[frameIndex][mfccIndex];
      }
    }

    return result;
  }

  Future<LingoJoyPrediction> predictFromMfcc(List<List<double>> mfcc) async {
    final interpreter = _interpreter;

    if (interpreter == null || _labels.isEmpty) {
      throw StateError('Model ASR belum diload.');
    }

    if (mfcc.isEmpty || mfcc.first.length != mfccCount) {
      throw ArgumentError('Input MFCC harus berbentuk [frames, 40].');
    }

    final fixedMfcc = _padOrTruncateMfcc(mfcc);

    final input = [fixedMfcc];

    final output = [List<double>.filled(_labels.length, 0.0)];

    debugPrint('ASR RUN INPUT SHAPE: [1, $fixedFrames, $mfccCount]');
    debugPrint('ASR RUN OUTPUT SHAPE: [1, ${_labels.length}]');

    interpreter.run(input, output);

    final probabilities = output.first;

    final indexedProbabilities = <MapEntry<int, double>>[];

    for (int i = 0; i < probabilities.length; i++) {
      indexedProbabilities.add(MapEntry(i, probabilities[i]));
    }

    indexedProbabilities.sort((a, b) => b.value.compareTo(a.value));

    debugPrint('ASR TOP 5 PREDICTIONS');

    for (final entry in indexedProbabilities.take(5)) {
      debugPrint('${entry.key} | ${_labels[entry.key]} | ${entry.value}');
    }

    int bestIndex = 0;
    double bestConfidence = probabilities.first;

    for (int i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > bestConfidence) {
        bestIndex = i;
        bestConfidence = probabilities[i];
      }
    }

    return LingoJoyPrediction(
      label: _labels[bestIndex],
      confidence: bestConfidence,
      index: bestIndex,
    );
  }

  Future<void> debugTestWithDummyInput() async {
    await initialize();

    final random = Random(42);

    final dummyMfcc = List.generate(
      fixedFrames,
      (_) => List.generate(mfccCount, (_) => random.nextDouble() * 0.01),
    );

    final prediction = await predictFromMfcc(dummyMfcc);

    debugPrint('ASR DUMMY TEST');
    debugPrint('Label      : ${prediction.label}');
    debugPrint('Confidence : ${prediction.confidence}');
    debugPrint('Index      : ${prediction.index}');
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _labels = [];
  }
}
