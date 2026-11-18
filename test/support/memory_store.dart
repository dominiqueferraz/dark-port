import 'dart:convert';

import 'package:dark_port/tutorial_progress.dart';

class MemoryStore extends GameStore {
  Map<String, dynamic>? data;
  bool failNextWrite = false;

  @override
  Future<TutorialProgress?> load() async =>
      data == null ? null : TutorialProgress.fromJson(data!);

  @override
  Future<void> write(TutorialProgress save) async {
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('Storage unavailable');
    }
    data = jsonDecode(jsonEncode(save.toJson())) as Map<String, dynamic>;
  }
}
