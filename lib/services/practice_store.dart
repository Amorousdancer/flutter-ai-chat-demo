import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/practice_record.dart';

const String _defaultOfferLabStoreApiBaseUrl = String.fromEnvironment(
  'OFFERLAB_API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8787',
);

class PracticeStore extends ChangeNotifier {
  PracticeStore._({
    String? apiBaseUrl,
    http.Client? client,
  }) : _apiBaseUrl = apiBaseUrl ?? _defaultOfferLabStoreApiBaseUrl,
       _client = client ?? http.Client();

  static final PracticeStore instance = PracticeStore._();

  final String _apiBaseUrl;
  final http.Client _client;
  final List<PracticeRecord> _records = [];
  bool _didHydrate = false;

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

  Future<void> loadRemoteRecords() async {
    if (_didHydrate) {
      return;
    }
    _didHydrate = true;

    try {
      final response = await _client
          .get(Uri.parse('$_apiBaseUrl/api/practice-records'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        return;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List<dynamic>) {
        return;
      }

      _records
        ..clear()
        ..addAll(
          decoded
              .whereType<Map<String, dynamic>>()
              .map(PracticeRecord.fromJson),
        );
      notifyListeners();
    } catch (_) {
      // ponytail: keep the in-memory list usable when the backend is offline.
    }
  }

  Future<void> addRecord(PracticeRecord record) async {
    _records.insert(0, record);
    notifyListeners();

    try {
      await _client
          .post(
            Uri.parse('$_apiBaseUrl/api/practice-records'),
            headers: const {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(record.toJson()),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // ponytail: keep the optimistic local record even if sync fails.
    }
  }

  void clear() {
    if (_records.isEmpty) {
      return;
    }

    _records.clear();
    notifyListeners();
  }
}
