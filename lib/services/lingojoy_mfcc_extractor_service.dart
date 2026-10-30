import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

class LingoJoyMfccExtractorService {
  LingoJoyMfccExtractorService._internal();

  static final LingoJoyMfccExtractorService instance =
      LingoJoyMfccExtractorService._internal();

  static const int sampleRate = 16000;
  static const int nMfcc = 40;
  static const int nMels = 80;
  static const int nFft = 400;
  static const int winLength = 400;
  static const int hopLength = 160;
  static const double fMin = 20.0;
  static const double fMax = 7600.0;

  List<double>? _mean;
  List<double>? _std;
  List<List<double>>? _melFilterBank;
  List<List<double>>? _dctMatrix;
  List<double>? _window;

  Future<void> initialize() async {
    if (_mean != null && _std != null) return;

    final jsonText = await rootBundle.loadString(
      'assets/asr/normalization_stats.json',
    );

    final jsonData = jsonDecode(jsonText) as Map<String, dynamic>;

    _mean = (jsonData['mean'] as List)
        .map((value) => (value as num).toDouble())
        .toList();

    _std = (jsonData['std'] as List)
        .map((value) => (value as num).toDouble())
        .toList();

    if (_mean!.length != nMfcc || _std!.length != nMfcc) {
      throw StateError('Ukuran mean/std tidak sesuai jumlah MFCC.');
    }

    _melFilterBank = _buildMelFilterBankSlaney();
    _dctMatrix = _buildDctMatrix();
    _window = _hannWindow(winLength);
  }

  List<double> trimSilence(
    List<double> samples, {
    double topDb = 35.0,
    int frameLength = 512,
    int trimHopLength = 160,
    int paddingSamples = 2400,
  }) {
    if (samples.isEmpty) return samples;

    // Meniru pembentukan frame terpusat yang digunakan oleh
    // librosa.effects.trim melalui librosa.feature.rms(center: true).
    final halfFrame = frameLength ~/ 2;
    final centeredSamples = <double>[
      ...List<double>.filled(halfFrame, 0.0),
      ...samples,
      ...List<double>.filled(halfFrame, 0.0),
    ];

    final frameRmsValues = <double>[];

    for (
      int start = 0;
      start + frameLength <= centeredSamples.length;
      start += trimHopLength
    ) {
      double sum = 0.0;

      for (int i = 0; i < frameLength; i++) {
        final value = centeredSamples[start + i];
        sum += value * value;
      }

      frameRmsValues.add(sqrt(sum / frameLength));
    }

    if (frameRmsValues.isEmpty) return samples;

    final maxRms = frameRmsValues.reduce((a, b) => a > b ? a : b);

    // Sama seperti perilaku default librosa: audio dengan RMS seragam,
    // termasuk audio benar-benar hening, tidak dipotong seluruhnya.
    if (maxRms <= 1e-12) return samples;

    final threshold = maxRms * pow(10.0, -topDb / 20.0);

    int? firstNonSilentFrame;
    int? lastNonSilentFrame;

    for (int i = 0; i < frameRmsValues.length; i++) {
      if (frameRmsValues[i] > threshold) {
        firstNonSilentFrame ??= i;
        lastNonSilentFrame = i;
      }
    }

    if (firstNonSilentFrame == null || lastNonSilentFrame == null) {
      return samples;
    }

    // librosa.effects.trim memakai:
    // start = first_frame * hop_length
    // end   = (last_frame + 1) * hop_length
    final trimStart = firstNonSilentFrame * trimHopLength;
    final trimEnd = min(
      samples.length,
      (lastNonSilentFrame + 1) * trimHopLength,
    );

    final paddedStart = max(0, trimStart - paddingSamples);
    final paddedEnd = min(samples.length, trimEnd + paddingSamples);

    if (paddedEnd <= paddedStart) return samples;

    return samples.sublist(paddedStart, paddedEnd);
  }

  Future<List<List<double>>> extractNormalizedMfcc(List<double> samples) async {
    await initialize();

    final mfcc = _extractMfcc(samples);

    return mfcc.map((frame) {
      return List.generate(nMfcc, (index) {
        return (frame[index] - _mean![index]) / (_std![index] + 1e-8);
      });
    }).toList();
  }

  List<double> trimByEnergy(
    List<double> samples, {
    int frameLength = 512,
    int hopLength = 160,
    double absoluteThreshold = 0.008,
    double relativeRatio = 0.25,
    int paddingSamples = 1600,
  }) {
    if (samples.isEmpty) return samples;

    final rmsValues = <double>[];

    for (
      int start = 0;
      start + frameLength <= samples.length;
      start += hopLength
    ) {
      double sum = 0.0;

      for (int i = 0; i < frameLength; i++) {
        final value = samples[start + i];
        sum += value * value;
      }

      rmsValues.add(sqrt(sum / frameLength));
    }

    if (rmsValues.isEmpty) return samples;

    final maxRms = rmsValues.reduce((a, b) => a > b ? a : b);
    final threshold = max(absoluteThreshold, maxRms * relativeRatio);

    int firstFrame = 0;
    int lastFrame = rmsValues.length - 1;

    while (firstFrame < rmsValues.length && rmsValues[firstFrame] < threshold) {
      firstFrame++;
    }

    while (lastFrame > firstFrame && rmsValues[lastFrame] < threshold) {
      lastFrame--;
    }

    if (firstFrame >= lastFrame) return samples;

    final startSample = max(0, firstFrame * hopLength - paddingSamples);
    final endSample = min(
      samples.length,
      lastFrame * hopLength + frameLength + paddingSamples,
    );

    return samples.sublist(startSample, endSample);
  }

  List<double> cropLoudestSegment(
    List<double> samples, {
    double segmentSeconds = 1.2,
    int sampleRate = 16000,
    int frameLength = 512,
    int hopLength = 160,
  }) {
    if (samples.isEmpty) return samples;

    final segmentLength = (segmentSeconds * sampleRate).round();

    if (samples.length <= segmentLength) {
      return samples;
    }

    final rmsValues = <double>[];

    for (
      int start = 0;
      start + frameLength <= samples.length;
      start += hopLength
    ) {
      double sum = 0.0;

      for (int i = 0; i < frameLength; i++) {
        final value = samples[start + i];
        sum += value * value;
      }

      rmsValues.add(sqrt(sum / frameLength));
    }

    if (rmsValues.isEmpty) return samples;

    int peakFrame = 0;
    double peakRms = rmsValues.first;

    for (int i = 1; i < rmsValues.length; i++) {
      if (rmsValues[i] > peakRms) {
        peakRms = rmsValues[i];
        peakFrame = i;
      }
    }

    final peakSample = peakFrame * hopLength;

    int startSample = peakSample - segmentLength ~/ 2;
    startSample = max(0, startSample);

    int endSample = startSample + segmentLength;

    if (endSample > samples.length) {
      endSample = samples.length;
      startSample = max(0, endSample - segmentLength);
    }

    return samples.sublist(startSample, endSample);
  }

  List<double> normalizePeak(List<double> samples, {double targetPeak = 0.8}) {
    if (samples.isEmpty) return samples;

    final maxAbs = samples
        .map((value) => value.abs())
        .reduce((a, b) => a > b ? a : b);

    if (maxAbs < 1e-6) return samples;

    final gain = targetPeak / maxAbs;

    return samples.map((value) {
      return (value * gain).clamp(-1.0, 1.0);
    }).toList();
  }

  List<List<double>> _extractMfcc(List<double> samples) {
    if (samples.length < winLength) {
      final padded = List<double>.from(samples);

      while (padded.length < winLength) {
        padded.add(0.0);
      }

      samples = padded;
    }

    final melFilterBank = _melFilterBank!;
    final dctMatrix = _dctMatrix!;
    final window = _window!;

    final frames = <List<double>>[];

    for (
      int start = 0;
      start + winLength <= samples.length;
      start += hopLength
    ) {
      final frame = List<double>.generate(
        winLength,
        (index) => samples[start + index] * window[index],
      );

      final powerSpectrum = _powerSpectrum(frame);
      final melEnergies = _applyMelFilterBank(powerSpectrum, melFilterBank);
      final logMelDb = _powerToDb(melEnergies);
      final mfccFrame = _applyDct(logMelDb, dctMatrix);

      frames.add(mfccFrame);
    }

    if (frames.isEmpty) {
      throw StateError('MFCC kosong. Audio terlalu pendek.');
    }

    return frames;
  }

  List<double> _hannWindow(int length) {
    return List<double>.generate(length, (index) {
      return 0.5 - 0.5 * cos(2.0 * pi * index / length);
    });
  }

  List<double> _powerSpectrum(List<double> frame) {
    final binCount = (nFft ~/ 2) + 1;
    final spectrum = List<double>.filled(binCount, 0.0);

    for (int bin = 0; bin < binCount; bin++) {
      double real = 0.0;
      double imag = 0.0;

      for (int n = 0; n < nFft; n++) {
        final sample = n < frame.length ? frame[n] : 0.0;
        final angle = -2.0 * pi * bin * n / nFft;

        real += sample * cos(angle);
        imag += sample * sin(angle);
      }

      spectrum[bin] = real * real + imag * imag;
    }

    return spectrum;
  }

  List<List<double>> _buildMelFilterBankSlaney() {
    final binCount = (nFft ~/ 2) + 1;

    final fftFreqs = List<double>.generate(binCount, (index) {
      return sampleRate * index / nFft;
    });

    final minMel = _hzToMelSlaney(fMin);
    final maxMel = _hzToMelSlaney(fMax);

    final melPoints = List<double>.generate(nMels + 2, (index) {
      return minMel + (maxMel - minMel) * index / (nMels + 1);
    });

    final hzPoints = melPoints.map(_melToHzSlaney).toList();

    final filterBank = List.generate(
      nMels,
      (_) => List<double>.filled(binCount, 0.0),
    );

    for (int melIndex = 0; melIndex < nMels; melIndex++) {
      final leftHz = hzPoints[melIndex];
      final centerHz = hzPoints[melIndex + 1];
      final rightHz = hzPoints[melIndex + 2];

      for (int bin = 0; bin < binCount; bin++) {
        final freq = fftFreqs[bin];

        final lower = (freq - leftHz) / max(centerHz - leftHz, 1e-12);
        final upper = (rightHz - freq) / max(rightHz - centerHz, 1e-12);

        final weight = max(0.0, min(lower, upper));

        final slaneyNorm = 2.0 / max(rightHz - leftHz, 1e-12);

        filterBank[melIndex][bin] = weight * slaneyNorm;
      }
    }

    return filterBank;
  }

  List<double> _applyMelFilterBank(
    List<double> powerSpectrum,
    List<List<double>> melFilterBank,
  ) {
    return melFilterBank.map((filter) {
      double sum = 0.0;

      for (int i = 0; i < powerSpectrum.length; i++) {
        sum += powerSpectrum[i] * filter[i];
      }

      return sum;
    }).toList();
  }

  List<double> _powerToDb(List<double> values) {
    final dbValues = values.map((value) {
      return 10.0 * log(max(value, 1e-10)) / ln10;
    }).toList();

    final maxDb = dbValues.reduce((a, b) => a > b ? a : b);
    final floorDb = maxDb - 80.0;

    return dbValues.map((value) {
      return max(value, floorDb);
    }).toList();
  }

  List<List<double>> _buildDctMatrix() {
    return List.generate(nMfcc, (mfccIndex) {
      return List.generate(nMels, (melIndex) {
        final scale = mfccIndex == 0 ? sqrt(1.0 / nMels) : sqrt(2.0 / nMels);

        return scale *
            cos(pi * mfccIndex * (2.0 * melIndex + 1.0) / (2.0 * nMels));
      });
    });
  }

  List<double> _applyDct(List<double> logMelDb, List<List<double>> dctMatrix) {
    return List.generate(nMfcc, (mfccIndex) {
      double sum = 0.0;

      for (int melIndex = 0; melIndex < nMels; melIndex++) {
        sum += dctMatrix[mfccIndex][melIndex] * logMelDb[melIndex];
      }

      return sum;
    });
  }

  double _hzToMelSlaney(double hz) {
    const double fSp = 200.0 / 3.0;
    const double minLogHz = 1000.0;
    const double minLogMel = minLogHz / fSp;
    final double logStep = log(6.4) / 27.0;

    if (hz >= minLogHz) {
      return minLogMel + log(hz / minLogHz) / logStep;
    }

    return hz / fSp;
  }

  double _melToHzSlaney(double mel) {
    const double fSp = 200.0 / 3.0;
    const double minLogHz = 1000.0;
    const double minLogMel = minLogHz / fSp;
    final double logStep = log(6.4) / 27.0;

    if (mel >= minLogMel) {
      return minLogHz * exp(logStep * (mel - minLogMel));
    }

    return mel * fSp;
  }
}
