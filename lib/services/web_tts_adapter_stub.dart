class WebTtsAdapter {
  static Future<void> speak(String text) async {
    throw UnsupportedError('Web TTS hanya tersedia saat aplikasi berjalan di browser.');
  }

  static Future<void> stop() async {}

  static Future<void> dispose() async {}
}
