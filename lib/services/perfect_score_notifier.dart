import 'package:flutter/material.dart';

import 'database_service.dart';

class PerfectScoreNotifier {
  static final ValueNotifier<int> count = ValueNotifier<int>(0);

  static Future<void> refresh() async {
    final value = await DatabaseService.instance.getPerfectPracticeCount();
    count.value = value;
  }
}
