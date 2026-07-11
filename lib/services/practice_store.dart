import 'package:flutter/foundation.dart';

import '../models/practice_record.dart';

class PracticeStore extends ChangeNotifier {
  PracticeStore._();

  static final PracticeStore instance = PracticeStore._();

  final List<PracticeRecord> _records = [];

  List<PracticeRecord> get records {
    return List<PracticeRecord>.unmodifiable(_records);
  }

  int get totalPractices => _records.length;

  int get averageScore {
    if (_records.isEmpty) {
      return 0;
    }

    final totalScore = _records.fold<int>(
      0,
      (sum, record) => sum + record.score,
    );
    return (totalScore / _records.length).round();
  }

  int get bestScore {
    if (_records.isEmpty) {
      return 0;
    }

    return _records
        .map((record) => record.score)
        .reduce((current, next) => current > next ? current : next);
  }

  PracticeRecord? get latestRecord {
    if (_records.isEmpty) {
      return null;
    }

    return _records.first;
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
