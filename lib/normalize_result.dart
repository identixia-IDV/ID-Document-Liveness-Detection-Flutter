import 'dart:convert';

/// Customer process JSON: identity, readings, tests, images, session.
typedef JsonMap = Map<String, dynamic>;

const IMAGE_QA_ORDER = [
  'focus',
  'glares',
  'resolution',
  'colorness',
  'perspective',
  'bounds',
  'portrait',
  'handwritten',
  'brightness',
  'occlusion',
];

String _firstString(JsonMap row, List<String> keys, [String fallback = '']) {
  for (final key in keys) {
    final value = row[key];
    if (value is String && value.isNotEmpty) return value;
    if (value != null && value is! String) return '$value';
  }
  return fallback;
}

String remapName(String value) {
  return switch (value) {
    'surname' => 'familyName',
    'givenNames' => 'firstNames',
    'documentNumber' => 'docNumber',
    'hologramIntegrity' => 'foilCheck',
    'portrait' => 'face',
    _ => value,
  };
}

String remapOrigin(String value) {
  return switch (value.trim().toLowerCase()) {
    'ocr' => 'visual',
    'mrz' => 'zone',
    'barcode' => 'code',
    'rfid' => 'chip',
    _ => value,
  };
}

String remapGroup(String value) {
  return switch (value.trim().toLowerCase()) {
    'verify' => 'validity',
    'quality' => 'capture',
    'security' => 'authenticity',
    'liveness' => 'authenticity',
    _ => value,
  };
}

String remapOutcome(String value) {
  final s = value.trim().toLowerCase();
  return s == 'skip' ? 'hold' : s;
}

String remapDetail(String value) {
  if (value == 'ok') return 'ready';
  if (value == 'processing failed') return 'failed';
  return value;
}

class DocImage {
  DocImage({required this.name, this.page, this.data});

  final String name;
  final int? page;
  final String? data;

  String get id => name;
  String? get image => data;

  JsonMap toJson() {
    final out = <String, dynamic>{'name': name};
    if (page != null) out['page'] = page;
    if (data != null) out['data'] = data;
    return out;
  }
}

class DocField {
  DocField({
    required this.name,
    required this.value,
    required this.origin,
    this.score,
    this.origins,
  });

  final String name;
  final String value;
  final String origin;
  final num? score;
  final List<dynamic>? origins;

  String get id => name;
  String get source => origin;
  List<dynamic>? get sources => origins;

  JsonMap toJson() {
    final out = <String, dynamic>{
      'name': name,
      'value': value,
      'origin': origin,
    };
    if (score != null) out['score'] = score;
    if (origins != null) out['origins'] = origins;
    return out;
  }
}

class DocCheck {
  DocCheck({
    required this.name,
    required this.group,
    required this.outcome,
    this.score,
    this.page,
    this.note,
  });

  final String name;
  final String group;
  final String outcome;
  final num? score;
  final int? page;
  final String? note;

  String get id => name;
  String get kind => group;
  String get result => outcome;
  String? get reason => note;

  JsonMap toJson() {
    final out = <String, dynamic>{
      'name': name,
      'group': group,
      'outcome': outcome,
    };
    if (score != null) out['score'] = score;
    if (page != null) out['page'] = page;
    if (note != null && note!.isNotEmpty) out['note'] = note;
    return out;
  }
}

class DocIdent {
  DocIdent({this.klass, this.country, this.score});

  final String? klass;
  final String? country;
  final num? score;

  String? get type => klass;

  JsonMap toJson() {
    final out = <String, dynamic>{};
    if (klass != null) out['class'] = klass;
    if (country != null) out['country'] = country;
    if (score != null) out['score'] = score;
    return out;
  }
}

class DocMeta {
  DocMeta({this.code, this.jobId, this.detail, this.at});

  final int? code;
  final String? jobId;
  final String? detail;
  final String? at;

  int? get status => code;
  String? get transactionId => jobId;
  String? get message => detail;
  String? get timestamp => at;

  JsonMap toJson() {
    final out = <String, dynamic>{};
    if (jobId != null) out['jobId'] = jobId;
    if (code != null) out['code'] = code;
    if (detail != null) out['detail'] = detail;
    if (at != null) out['at'] = at;
    return out;
  }
}

/// Typed customer process body. Does not rebuild visual/authenticity maps.
class DocResult {
  DocResult({
    this.session,
    this.identity,
    List<DocField>? readings,
    List<DocCheck>? tests,
    List<DocImage>? images,
    Map<String, dynamic>? extra,
  })  : readings = readings ?? [],
        tests = tests ?? [],
        images = images ?? [],
        extra = extra ?? {};

  DocMeta? session;
  DocIdent? identity;
  List<DocField> readings;
  List<DocCheck> tests;
  List<DocImage> images;
  Map<String, dynamic> extra;

  DocMeta? get metadata => session;
  int? get code => session?.code;
  String? get message => session?.detail;
  DocIdent? get document => identity;
  List<DocField> get fields => readings;
  List<DocCheck> get checks => tests;

  JsonMap toJson() {
    final out = <String, dynamic>{};
    if (identity != null) out['identity'] = identity!.toJson();
    out['readings'] = readings.map((e) => e.toJson()).toList();
    out['tests'] = tests.map((e) => e.toJson()).toList();
    out['images'] = images.map((e) => e.toJson()).toList();
    if (session != null) out['session'] = session!.toJson();
    for (final e in extra.entries) {
      if (!out.containsKey(e.key)) out[e.key] = e.value;
    }
    return out;
  }
}

/// Kept for API compatibility. Reads tests where group == capture.
Map<String, dynamic> extractImageQualityChecks(dynamic value) {
  final out = <String, dynamic>{};
  if (value is List) {
    for (final item in value) {
      if (item is! Map) continue;
      final group = remapGroup('${item['group'] ?? item['kind'] ?? ''}');
      if (group != 'capture') continue;
      final id = remapName('${item['name'] ?? item['id'] ?? ''}');
      if (id.isNotEmpty) {
        out[id] = item['score'] ?? item['outcome'] ?? item['result'];
      }
    }
  }
  return out;
}

num? statusCode(dynamic value) {
  if (value is num) return value;
  if (value is String && value.trim().isNotEmpty) return num.tryParse(value);
  return null;
}

JsonMap? _asObject(dynamic value) {
  if (value is JsonMap) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

num? _asNum(dynamic value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value);
  return null;
}

JsonMap? _parseRoot(String raw) {
  try {
    final decoded = jsonDecode(raw);
    return _asObject(decoded);
  } catch (_) {
    return null;
  }
}

DocResult normalizeResult(String raw) {
  final obj = _parseRoot(raw.trim());
  if (obj == null) return DocResult();

  final ident = _asObject(obj['identity']) ?? _asObject(obj['document']);
  final readings = <DocField>[];
  final rawReadings = obj['readings'] is List ? obj['readings'] : obj['fields'];
  if (rawReadings is List) {
    for (final item in rawReadings) {
      final row = _asObject(item);
      if (row == null) continue;
      readings.add(DocField(
        name: remapName(_firstString(row, ['name', 'id'])),
        value: row['value'] == null ? '' : '${row['value']}',
        origin: remapOrigin(_firstString(row, ['origin', 'source'], 'field')),
        score: _asNum(row['score']),
        origins: (row['origins'] ?? row['sources']) is List
            ? List<dynamic>.from((row['origins'] ?? row['sources']) as List)
            : null,
      ));
    }
  }

  final tests = <DocCheck>[];
  final rawTests = obj['tests'] is List ? obj['tests'] : obj['checks'];
  if (rawTests is List) {
    for (final item in rawTests) {
      final row = _asObject(item);
      if (row == null) continue;
      tests.add(DocCheck(
        name: remapName(_firstString(row, ['name', 'id'])),
        group: remapGroup(_firstString(row, ['group', 'kind'], 'check')),
        outcome: remapOutcome(_firstString(row, ['outcome', 'result'], 'hold')),
        score: _asNum(row['score']),
        page: _asInt(row['page']),
        note: _firstString(row, ['note', 'reason']).isEmpty
            ? null
            : _firstString(row, ['note', 'reason']),
      ));
    }
  }

  final images = <DocImage>[];
  final rawImages = obj['images'];
  if (rawImages is List) {
    for (final item in rawImages) {
      final row = _asObject(item);
      if (row == null) continue;
      final data = row['data'] is String
          ? row['data'] as String
          : (row['image'] is String ? row['image'] as String : null);
      images.add(DocImage(
        name: remapName(_firstString(row, ['name', 'id'], 'image')),
        page: _asInt(row['page']),
        data: data,
      ));
    }
  }

  const known = {
    'session',
    'identity',
    'readings',
    'tests',
    'images',
    'metadata',
    'code',
    'message',
    'document',
    'fields',
    'checks',
  };
  final extra = <String, dynamic>{};
  for (final e in obj.entries) {
    if (!known.contains(e.key)) extra[e.key] = e.value;
  }

  final sessionObj = _asObject(obj['session']) ?? _asObject(obj['metadata']) ?? {};
  final code = _asInt(sessionObj['code']) ?? _asInt(sessionObj['status']) ?? _asInt(obj['code']);
  final detailRaw = sessionObj['detail'] is String
      ? sessionObj['detail'] as String
      : (sessionObj['message'] is String
          ? sessionObj['message'] as String
          : (obj['message'] is String ? obj['message'] as String : null));
  final jobId = sessionObj['jobId'] is String
      ? sessionObj['jobId'] as String
      : (sessionObj['transactionId'] is String ? sessionObj['transactionId'] as String : null);

  return DocResult(
    session: DocMeta(
      code: code,
      jobId: jobId,
      detail: detailRaw == null ? null : remapDetail(detailRaw),
      at: sessionObj['at'] is String
          ? sessionObj['at'] as String
          : (sessionObj['timestamp'] is String ? sessionObj['timestamp'] as String : null),
    ),
    identity: ident == null
        ? null
        : DocIdent(
            klass: ident['class'] is String
                ? ident['class'] as String
                : (ident['type'] is String ? ident['type'] as String : null),
            country: ident['country'] is String ? ident['country'] as String : null,
            score: _asNum(ident['score']),
          ),
    readings: readings,
    tests: tests,
    images: images,
    extra: extra,
  );
}

String normalizeResultJson(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return raw;
  try {
    jsonDecode(trimmed);
  } catch (_) {
    return raw;
  }
  return jsonEncode(normalizeResult(trimmed).toJson());
}
