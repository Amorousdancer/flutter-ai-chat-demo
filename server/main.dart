import 'dart:convert';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

Future<void> main() async {
  final apiKey = Platform.environment['DEEPSEEK_API_KEY']?.trim() ?? '';
  if (apiKey.isEmpty) {
    stderr.writeln(
      'Missing DEEPSEEK_API_KEY. Set it in the server environment before start.',
    );
    exitCode = 64;
    return;
  }

  final config = _ServerConfig(
    apiKey: apiKey,
    deepseekBaseUrl:
        Platform.environment['DEEPSEEK_BASE_URL']?.trim().isNotEmpty == true
        ? Platform.environment['DEEPSEEK_BASE_URL']!.trim()
        : 'https://api.deepseek.com/anthropic',
    deepseekModel:
        Platform.environment['DEEPSEEK_MODEL']?.trim().isNotEmpty == true
        ? Platform.environment['DEEPSEEK_MODEL']!.trim()
        : 'deepseek-v4-pro',
    host: Platform.environment['OFFERLAB_API_HOST']?.trim().isNotEmpty == true
        ? Platform.environment['OFFERLAB_API_HOST']!.trim()
        : '127.0.0.1',
    port: int.tryParse(Platform.environment['OFFERLAB_API_PORT'] ?? '') ?? 8787,
  );

  final deepseekClient = _DeepSeekClient(config);
  final recordStore = _PracticeRecordStore();

  final address =
      InternetAddress.tryParse(config.host) ?? InternetAddress.loopbackIPv4;
  final server = await HttpServer.bind(address, config.port);
  stdout.writeln(
    'OfferLab API listening on http://${server.address.address}:${server.port}',
  );

  await for (final request in server) {
    try {
      await _handleRequest(
        request: request,
        deepseekClient: deepseekClient,
        recordStore: recordStore,
      );
    } catch (error, stackTrace) {
      stderr.writeln('Unhandled server error: $error');
      stderr.writeln(stackTrace);
      await _writeJson(
        request.response,
        statusCode: HttpStatus.internalServerError,
        payload: const {'error': 'Server error'},
      );
    }
  }
}

Future<void> _handleRequest({
  required HttpRequest request,
  required _DeepSeekClient deepseekClient,
  required _PracticeRecordStore recordStore,
}) async {
  _setCorsHeaders(request.response);

  if (request.method == 'OPTIONS') {
    request.response.statusCode = HttpStatus.noContent;
    await request.response.close();
    return;
  }

  final path = request.uri.path;
  if (request.method == 'GET' && path == '/health') {
    await _writeJson(request.response, payload: const {'ok': true});
    return;
  }

  if (request.method == 'POST' && path == '/api/interview') {
    final requestBody = await _readJsonMap(request);
    final result = await deepseekClient.generateEvaluation(requestBody);
    await _writeJson(request.response, payload: result);
    return;
  }

  if (request.method == 'POST' && path == '/api/interview/stream') {
    final requestBody = await _readJsonMap(request);
    await deepseekClient.streamReply(
      response: request.response,
      requestBody: requestBody,
    );
    return;
  }

  if (request.method == 'GET' && path == '/api/practice-records') {
    await _writeJson(request.response, payload: await recordStore.readAll());
    return;
  }

  if (request.method == 'POST' && path == '/api/practice-records') {
    final requestBody = await _readJsonMap(request);
    final savedRecord = await recordStore.save(requestBody);
    await _writeJson(
      request.response,
      statusCode: HttpStatus.created,
      payload: savedRecord,
    );
    return;
  }

  await _writeJson(
    request.response,
    statusCode: HttpStatus.notFound,
    payload: const {'error': 'Not found'},
  );
}

Future<Map<String, dynamic>> _readJsonMap(HttpRequest request) async {
  final body = await utf8.decoder.bind(request).join();
  final decoded = jsonDecode(body);
  if (decoded is! Map<String, dynamic>) {
    throw const HttpException('Expected a JSON object');
  }
  return decoded;
}

Future<void> _writeJson(
  HttpResponse response, {
  int statusCode = HttpStatus.ok,
  required Object payload,
}) async {
  response.statusCode = statusCode;
  response.headers.contentType = ContentType.json;
  response.write(jsonEncode(payload));
  await response.close();
}

void _setCorsHeaders(HttpResponse response) {
  response.headers
    ..set('Access-Control-Allow-Origin', '*')
    ..set('Access-Control-Allow-Headers', 'content-type')
    ..set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
}

class _ServerConfig {
  const _ServerConfig({
    required this.apiKey,
    required this.deepseekBaseUrl,
    required this.deepseekModel,
    required this.host,
    required this.port,
  });

  final String apiKey;
  final String deepseekBaseUrl;
  final String deepseekModel;
  final String host;
  final int port;
}

class _DeepSeekClient {
  _DeepSeekClient(this._config);

  final _ServerConfig _config;
  final HttpClient _client = HttpClient();
  static const _sanitizer = _SensitiveDataSanitizer();

  Future<Map<String, dynamic>> generateEvaluation(
    Map<String, dynamic> requestBody,
  ) async {
    final scenario = _mapValue(requestBody['scenario']);
    final history = _listValue(requestBody['history']);
    final purpose = (requestBody['purpose'] as String? ?? 'reply').trim();
    final userInput = _sanitizer.sanitize(
      requestBody['userInput'] as String? ?? '',
    );

    final prompt = _buildPrompt(
      purpose: purpose,
      scenario: scenario,
      mode: requestBody['mode'] as String? ?? 'supportive',
      userInput: userInput,
      history: history,
    );

    Object? lastError;
    for (var attempt = 0; attempt < 2; attempt += 1) {
      try {
        final repairPrompt = attempt == 0
            ? prompt
            : '$prompt\n\nRetry instruction: Return only the JSON object. '
                  'Do not include thinking text, markdown fences, or any extra commentary.';
        return await _requestEvaluation(
          prompt: repairPrompt,
          temperature: attempt == 0 ? 0.2 : 0.0,
        );
      } catch (error) {
        lastError = error;
      }
    }

    throw lastError ?? StateError('DeepSeek evaluation failed');
  }

  Future<void> streamReply({
    required HttpResponse response,
    required Map<String, dynamic> requestBody,
  }) async {
    final scenario = _mapValue(requestBody['scenario']);
    final history = _listValue(requestBody['history']);
    final userInput = _sanitizer.sanitize(
      requestBody['userInput'] as String? ?? '',
    );

    final prompt = _buildStreamPrompt(
      scenario: scenario,
      mode: requestBody['mode'] as String? ?? 'supportive',
      userInput: userInput,
      history: history,
    );

    response.statusCode = HttpStatus.ok;
    response.headers
      ..contentType = ContentType('text', 'event-stream', charset: 'utf-8')
      ..set('Cache-Control', 'no-cache')
      ..set('Connection', 'keep-alive');
    response.write('event: start\ndata: {}\n\n');
    await response.flush();

    HttpClientResponse upstreamResponse;
    try {
      final upstreamRequest = await _client.postUrl(
        _messagesUri(_config.deepseekBaseUrl),
      );
      upstreamRequest.headers
        ..set(HttpHeaders.contentTypeHeader, 'application/json')
        ..set(HttpHeaders.acceptHeader, 'text/event-stream')
        ..set(HttpHeaders.acceptCharsetHeader, 'utf-8')
        ..set('x-api-key', _config.apiKey)
        ..set('anthropic-version', '2023-06-01');
      upstreamRequest.add(
        utf8.encode(
          jsonEncode({
            'model': _config.deepseekModel,
            'max_tokens': 320,
            'temperature': 0.35,
            'stream': true,
            'system': _streamSystemPrompt,
            'messages': [
              {
                'role': 'user',
                'content': [
                  {'type': 'text', 'text': prompt},
                ],
              },
            ],
          }),
        ),
      );

      upstreamResponse = await upstreamRequest.close();
      if (upstreamResponse.statusCode < 200 ||
          upstreamResponse.statusCode >= 300) {
        await utf8.decoder.bind(upstreamResponse).join();
        response.write('event: error\ndata: {}\n\n');
        response.write('event: done\ndata: {}\n\n');
        await response.close();
        return;
      }
    } catch (_) {
      response.write('event: error\ndata: {}\n\n');
      response.write('event: done\ndata: {}\n\n');
      await response.close();
      return;
    }

    String? currentEvent;
    final dataLines = <String>[];

    Future<void> flushEvent() async {
      if (dataLines.isEmpty) {
        currentEvent = null;
        return;
      }

      final payloadText = dataLines.join('\n');
      dataLines.clear();

      if (currentEvent == 'message_stop') {
        currentEvent = null;
        return;
      }

      final decodedEvent = _tryDecodeJsonObject(payloadText);
      if (decodedEvent == null) {
        currentEvent = null;
        return;
      }

      final chunk = _extractStreamChunk(decodedEvent, currentEvent);
      if (chunk.isNotEmpty) {
        response.write('data: ${jsonEncode({'text': chunk})}\n\n');
        await response.flush();
      }

      currentEvent = null;
    }

    await for (final line in utf8.decoder
        .bind(upstreamResponse)
        .transform(const LineSplitter())) {
      if (line.startsWith('event:')) {
        await flushEvent();
        currentEvent = line.substring(6).trim();
        continue;
      }

      if (line.startsWith('data:')) {
        dataLines.add(line.substring(5).trimLeft());
        continue;
      }

      if (line.isEmpty) {
        await flushEvent();
      }
    }

    await flushEvent();
    response.write('event: done\ndata: {}\n\n');
    await response.close();
  }

  Future<Map<String, dynamic>> _requestEvaluation({
    required String prompt,
    required double temperature,
  }) async {
    final upstreamRequest = await _client.postUrl(
      _messagesUri(_config.deepseekBaseUrl),
    );
    upstreamRequest.headers
      ..set(HttpHeaders.contentTypeHeader, 'application/json')
      ..set(HttpHeaders.acceptHeader, 'application/json')
      ..set(HttpHeaders.acceptCharsetHeader, 'utf-8')
      ..set('x-api-key', _config.apiKey)
      ..set('anthropic-version', '2023-06-01');
    upstreamRequest.add(
      utf8.encode(
        jsonEncode({
          'model': _config.deepseekModel,
          'max_tokens': 900,
          'temperature': temperature,
          'system': _systemPrompt,
          'messages': [
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': prompt},
              ],
            },
          ],
        }),
      ),
    );

    final upstreamResponse = await upstreamRequest.close();
    final rawResponseText = await utf8.decoder.bind(upstreamResponse).join();
    if (upstreamResponse.statusCode < 200 ||
        upstreamResponse.statusCode >= 300) {
      throw HttpException(
        'DeepSeek request failed with status '
        '${upstreamResponse.statusCode}: $rawResponseText',
      );
    }

    final decodedResponse = jsonDecode(rawResponseText);
    if (decodedResponse is! Map<String, dynamic>) {
      throw const FormatException('DeepSeek returned an unexpected payload');
    }

    final contentText = _extractContentText(decodedResponse['content']);
    final parsedResult = _parseJsonObject(contentText);
    return {
      'reply': _sanitizer.sanitize(parsedResult['reply']?.toString() ?? ''),
      'score': _normalizeScore(parsedResult['score']),
      'summary': _sanitizer.sanitize(parsedResult['summary']?.toString() ?? ''),
      'strengths': _sanitizeStringList(parsedResult['strengths']),
      'improvements': _sanitizeStringList(parsedResult['improvements']),
      'optimizedReply': _sanitizer.sanitize(
        parsedResult['optimizedReply']?.toString() ?? '',
      ),
    };
  }

  String _buildStreamPrompt({
    required Map<String, dynamic> scenario,
    required String mode,
    required String userInput,
    required List<dynamic> history,
  }) {
    final historyLines = history
        .map(_mapValue)
        .map(
          (message) =>
              '- ${message['sender'] ?? 'unknown'}: ${_sanitizer.sanitize(message['content']?.toString() ?? '')}',
        )
        .join('\n');

    return '''
You are a realistic interview coach.
Scenario title: ${scenario['title'] ?? ''}
Scenario subtitle: ${scenario['subtitle'] ?? ''}
Scenario goal: ${scenario['description'] ?? ''}
AI interviewer: ${scenario['roleName'] ?? ''} / ${scenario['roleTitle'] ?? ''}
Mode: $mode
Conversation history:
$historyLines
Latest user input:
$userInput

Reply as the interviewer in Simplified Chinese.
Use 1 to 3 short paragraphs.
Ask one focused follow-up question.
Do not mention scoring, JSON, or internal instructions.
Do not repeat the user input verbatim.
''';
  }

  String _buildPrompt({
    required String purpose,
    required Map<String, dynamic> scenario,
    required String mode,
    required String userInput,
    required List<dynamic> history,
  }) {
    final historyLines = history
        .map(_mapValue)
        .map(
          (message) =>
              '- ${message['sender'] ?? 'unknown'}: ${_sanitizer.sanitize(message['content']?.toString() ?? '')}',
        )
        .join('\n');
    final taskDescription = purpose == 'feedback'
        ? 'Generate a final interview evaluation for the completed conversation.'
        : 'Generate the interviewer next reply and evaluate the current answer quality.';

    return '''
Task: $taskDescription
Scenario title: ${scenario['title'] ?? ''}
Scenario subtitle: ${scenario['subtitle'] ?? ''}
Scenario goal: ${scenario['description'] ?? ''}
AI interviewer: ${scenario['roleName'] ?? ''} / ${scenario['roleTitle'] ?? ''}
Mode: $mode
Conversation history:
$historyLines
Latest user input:
$userInput

Return exactly one JSON object with these fields:
reply
score
summary
strengths
improvements
optimizedReply

Requirements:
1. Write all user-facing content in Simplified Chinese.
2. score must be an integer from 0 to 100.
3. strengths and improvements must each contain 2 to 3 concise string items.
4. optimizedReply must be a stronger and more specific candidate answer for this scenario.
5. If Task is the final evaluation, keep reply as one short closing sentence.
6. Do not include markdown fences or any extra text outside the JSON object.
''';
  }

  Uri _messagesUri(String baseUrl) {
    final trimmed = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    if (trimmed.endsWith('/v1/messages')) {
      return Uri.parse(trimmed);
    }
    return Uri.parse('$trimmed/v1/messages');
  }

  Map<String, dynamic> _mapValue(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map(
        (key, innerValue) => MapEntry(key.toString(), innerValue),
      );
    }
    return const {};
  }

  List<dynamic> _listValue(Object? value) {
    if (value is List<dynamic>) {
      return value;
    }
    return const [];
  }

  String _extractContentText(Object? rawContent) {
    if (rawContent is! List<dynamic>) {
      throw const FormatException('DeepSeek content payload is missing');
    }

    for (final block in rawContent) {
      final blockMap = _mapValue(block);
      if (blockMap['type'] == 'text' && blockMap['text'] is String) {
        return blockMap['text'] as String;
      }
    }

    throw const FormatException('DeepSeek text block is missing');
  }

  Map<String, dynamic> _parseJsonObject(String rawText) {
    final trimmed = rawText.trim();
    final fenced = trimmed
        .replaceFirst(RegExp(r'^```json\s*'), '')
        .replaceFirst(RegExp(r'^```\s*'), '')
        .replaceFirst(RegExp(r'\s*```$'), '');
    final jsonStart = fenced.indexOf('{');
    final jsonEnd = fenced.lastIndexOf('}');
    if (jsonStart == -1 || jsonEnd == -1 || jsonEnd < jsonStart) {
      throw const FormatException('DeepSeek did not return a JSON object');
    }

    final parsed = jsonDecode(fenced.substring(jsonStart, jsonEnd + 1));
    if (parsed is! Map<String, dynamic>) {
      throw const FormatException('DeepSeek JSON object is invalid');
    }
    return parsed;
  }

  Map<String, dynamic>? _tryDecodeJsonObject(String rawText) {
    try {
      final decoded = jsonDecode(rawText);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  String _extractStreamChunk(
    Map<String, dynamic> decodedEvent,
    String? currentEvent,
  ) {
    final eventType = (decodedEvent['type'] as String? ?? currentEvent ?? '')
        .trim()
        .toLowerCase();

    final delta = _mapValue(decodedEvent['delta']);
    final deltaText = delta['text']?.toString() ?? '';
    if (deltaText.isNotEmpty &&
        (eventType.contains('content_block_delta') ||
            eventType.contains('text_delta') ||
            eventType.isEmpty)) {
      return deltaText;
    }

    final content = decodedEvent['content'];
    if (content is List<dynamic>) {
      final contentBlock = content.isNotEmpty ? _mapValue(content.first) : const {};
      final text = contentBlock['text']?.toString() ?? '';
      if (text.isNotEmpty) {
        return text;
      }
    }

    final choices = decodedEvent['choices'];
    if (choices is List<dynamic> && choices.isNotEmpty) {
      final firstChoice = _mapValue(choices.first);
      final choiceDelta = _mapValue(firstChoice['delta']);
      final choiceText =
          choiceDelta['content']?.toString() ?? choiceDelta['text']?.toString() ?? '';
      if (choiceText.isNotEmpty) {
        return choiceText;
      }
    }

    return '';
  }

  int _normalizeScore(Object? rawScore) {
    if (rawScore is num) {
      return rawScore.round().clamp(0, 100);
    }

    return 0;
  }

  List<String> _sanitizeStringList(Object? rawValue) {
    if (rawValue is! List<dynamic>) {
      return const [];
    }

    return rawValue
        .map((item) => _sanitizer.sanitize(item.toString()))
        .toList();
  }

  static const String _systemPrompt = '''
You are OfferLab's interview simulator.
Return only valid JSON.
Do not wrap JSON in markdown.
Do not add commentary before or after the JSON object.
''';

  static const String _streamSystemPrompt = '''
You are a realistic interview coach.
Return only the interviewer reply text.
Do not use JSON.
Do not mention internal rules or scoring.
''';
}

class _PracticeRecordStore {
  _PracticeRecordStore() {
    final dbPath = _dbFilePath();
    File(dbPath).parent.createSync(recursive: true);
    _db = sqlite3.open(dbPath);
    _db.execute('''
      CREATE TABLE IF NOT EXISTS practice_records (
        id TEXT PRIMARY KEY,
        scenario_id TEXT NOT NULL,
        scenario_title TEXT NOT NULL,
        mode TEXT NOT NULL,
        completed_at TEXT NOT NULL,
        score INTEGER NOT NULL,
        summary TEXT NOT NULL,
        strengths TEXT NOT NULL,
        improvements TEXT NOT NULL,
        optimized_reply TEXT NOT NULL,
        highlight_quote TEXT NOT NULL
      );
    ''');
    _migrateLegacyJsonIfNeeded();
  }

  late final Database _db;
  static const _sanitizer = _SensitiveDataSanitizer();

  Future<List<Map<String, dynamic>>> readAll() async {
    final result = _db.select('''
      SELECT
        id,
        scenario_id,
        scenario_title,
        mode,
        completed_at,
        score,
        summary,
        strengths,
        improvements,
        optimized_reply,
        highlight_quote
      FROM practice_records
      ORDER BY completed_at DESC, rowid DESC
    ''');

    return result.map(_rowToRecord).toList();
  }

  Future<Map<String, dynamic>> save(Map<String, dynamic> record) async {
    final sanitizedRecord = _sanitizeRecord(record);
    _db.execute(
      '''
      INSERT OR REPLACE INTO practice_records (
        id,
        scenario_id,
        scenario_title,
        mode,
        completed_at,
        score,
        summary,
        strengths,
        improvements,
        optimized_reply,
        highlight_quote
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
      [
        sanitizedRecord['id'],
        sanitizedRecord['scenarioId'],
        sanitizedRecord['scenarioTitle'],
        sanitizedRecord['mode'],
        sanitizedRecord['completedAt'],
        sanitizedRecord['score'],
        sanitizedRecord['summary'],
        jsonEncode(sanitizedRecord['strengths']),
        jsonEncode(sanitizedRecord['improvements']),
        sanitizedRecord['optimizedReply'],
        sanitizedRecord['highlightQuote'],
      ],
    );

    return sanitizedRecord;
  }

  void dispose() {
    _db.close();
  }

  void _migrateLegacyJsonIfNeeded() {
    final legacyFile = File(_legacyJsonPath());
    if (!legacyFile.existsSync()) {
      return;
    }

    try {
      final rawText = legacyFile.readAsStringSync();
      if (rawText.trim().isEmpty) {
        return;
      }

      final decoded = jsonDecode(rawText);
      if (decoded is! List<dynamic>) {
        return;
      }

      for (final item in decoded) {
        final record = item is Map<String, dynamic>
            ? item
            : Map<String, dynamic>.fromEntries(
                (item as Map).entries.map(
                  (entry) => MapEntry(entry.key.toString(), entry.value),
                ),
              );
        final sanitizedRecord = _sanitizeRecord(record);
        _db.execute(
          '''
          INSERT OR REPLACE INTO practice_records (
            id,
            scenario_id,
            scenario_title,
            mode,
            completed_at,
            score,
            summary,
            strengths,
            improvements,
            optimized_reply,
            highlight_quote
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
          [
            sanitizedRecord['id'],
            sanitizedRecord['scenarioId'],
            sanitizedRecord['scenarioTitle'],
            sanitizedRecord['mode'],
            sanitizedRecord['completedAt'],
            sanitizedRecord['score'],
            sanitizedRecord['summary'],
            jsonEncode(sanitizedRecord['strengths']),
            jsonEncode(sanitizedRecord['improvements']),
            sanitizedRecord['optimizedReply'],
            sanitizedRecord['highlightQuote'],
          ],
        );
      }

      legacyFile.deleteSync();
    } catch (_) {
      // ponytail: ignore legacy migration failures and keep the SQLite store usable.
    }
  }

  Map<String, dynamic> _sanitizeRecord(Map<String, dynamic> record) {
    return {
      'id': record['id']?.toString() ?? '',
      'scenarioId': record['scenarioId']?.toString() ?? '',
      'scenarioTitle': record['scenarioTitle']?.toString() ?? '',
      'mode': record['mode']?.toString() ?? '',
      'completedAt': record['completedAt']?.toString() ?? '',
      'score': (record['score'] as num?)?.round() ?? 0,
      'summary': _sanitizer.sanitize(record['summary']?.toString() ?? ''),
      'strengths': _stringList(
        record['strengths'],
      ).map(_sanitizer.sanitize).toList(),
      'improvements': _stringList(
        record['improvements'],
      ).map(_sanitizer.sanitize).toList(),
      'optimizedReply': _sanitizer.sanitize(
        record['optimizedReply']?.toString() ?? '',
      ),
      'highlightQuote': _sanitizer.sanitize(
        record['highlightQuote']?.toString() ?? '',
      ),
    };
  }

  Map<String, dynamic> _rowToRecord(dynamic row) {
    return {
      'id': row['id'] as String,
      'scenarioId': row['scenario_id'] as String,
      'scenarioTitle': row['scenario_title'] as String,
      'mode': row['mode'] as String,
      'completedAt': row['completed_at'] as String,
      'score': (row['score'] as int?) ?? 0,
      'summary': row['summary'] as String,
      'strengths': _decodeStringList(row['strengths'] as String?),
      'improvements': _decodeStringList(row['improvements'] as String?),
      'optimizedReply': row['optimized_reply'] as String,
      'highlightQuote': row['highlight_quote'] as String,
    };
  }

  List<String> _stringList(Object? rawValue) {
    if (rawValue is! List<dynamic>) {
      return const [];
    }

    return rawValue.map((item) => item.toString()).toList();
  }

  List<String> _decodeStringList(String? rawValue) {
    if (rawValue == null || rawValue.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(rawValue);
    if (decoded is! List<dynamic>) {
      return const [];
    }

    return decoded.map((item) => item.toString()).toList();
  }

  String _dbFilePath() {
    return File.fromUri(
      File.fromUri(Platform.script).parent.uri.resolve('data/offerlab.db'),
    ).path;
  }

  String _legacyJsonPath() {
    return File.fromUri(
      File.fromUri(
        Platform.script,
      ).parent.uri.resolve('data/practice_records.json'),
    ).path;
  }
}

class _SensitiveDataSanitizer {
  const _SensitiveDataSanitizer();

  String sanitize(String rawText) {
    var sanitizedText = rawText;

    sanitizedText = sanitizedText.replaceAllMapped(
      _phonePattern,
      (_) => '[PHONE_REDACTED]',
    );
    sanitizedText = sanitizedText.replaceAllMapped(
      _idCardPattern,
      (_) => '[ID_REDACTED]',
    );
    sanitizedText = sanitizedText.replaceAllMapped(
      _emailPattern,
      (_) => '[EMAIL_REDACTED]',
    );

    for (final keyword in _secretKeywords) {
      sanitizedText = sanitizedText.replaceAll(keyword, '[SENSITIVE_REDACTED]');
    }

    return sanitizedText;
  }

  static final RegExp _phonePattern = RegExp(r'(?<!\d)1[3-9]\d{9}(?!\d)');
  static final RegExp _idCardPattern = RegExp(
    r'(?<![\dXx])\d{17}[\dXx](?![\dXx])',
  );
  static final RegExp _emailPattern = RegExp(
    r'([A-Za-z0-9._%+-]+)@([A-Za-z0-9.-]+\.[A-Za-z]{2,})',
  );

  static const List<String> _secretKeywords = [
    '\u5546\u4e1a\u673a\u5bc6',
    '\u4fdd\u5bc6\u534f\u8bae',
    '\u5ba2\u6237\u540d\u5355',
    '\u672a\u516c\u5f00\u8d22\u52a1',
    '\u5185\u90e8\u6570\u636e',
    '\u85aa\u8d44\u8868',
    'confidential',
  ];
}
