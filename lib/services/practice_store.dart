import 'package:flutter/foundation.dart';

import '../models/practice_record.dart';

class PracticeStore extends ChangeNotifier {
  PracticeStore._();

  static final PracticeStore instance = PracticeStore._();

  final List<PracticeRecord> _records = [];

  List<PracticeRecord> get records {
    return List<PracticeRecord>.unmodifiable(_records);
  }

  void addRecord(PracticeRecord record) {
    _records.insert(0, record);
    notifyListeners();
  }

  void clear() {
    if (_records.isEmpty) {
      return;
    }

    _records.clear();
    notifyListeners();
  }
}
