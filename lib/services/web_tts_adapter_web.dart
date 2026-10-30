// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
// ignore: deprecated_member_use
import 'dart:html' as html;

class WebTtsAdapter {
  // ignore: unused_field
  static html.SpeechSynthesisUtterance? _currentUtterance;

  static Future<void> speak(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;

    await stop();

    final synth = html.window.speechSynthesis;
    if (synth == null) {
      throw Exception('TTS browser tidak tersedia pada perangkat ini.');
    }

    final completer = Completer<void>();
    final utterance = html.SpeechSynthesisUtterance(trimmedText)
      ..lang = 'en-US'
      ..rate = 0.82
      ..pitch = 1.05
      ..volume = 1.0;

    _currentUtterance = utterance;

    utterance.onEnd.listen((_) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });

    utterance.onError.listen((event) {
      if (!completer.isCompleted) {
        completer.completeError(Exception('TTS browser gagal memutar suara.'));
      }
    });

    synth.speak(utterance);

    await completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () async {
        await stop();
      },
    );
  }

  static Future<void> stop() async {
    final synth = html.window.speechSynthesis;
    synth?.cancel();
    _currentUtterance = null;
  }

  static Future<void> dispose() async {
    await stop();
  }
}
