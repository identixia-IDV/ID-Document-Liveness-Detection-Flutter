import 'dart:convert';
import 'dart:typed_data';

import '../normalize_result.dart';

class FieldRow {
  FieldRow({required this.key, required this.value, required this.source});
  final String key;
  final String value;
  final String source;
}

class SecurityRow {
  SecurityRow({required this.page, required this.check, required this.status});
  final String page;
  final String check;
  final String status;
}

class IdentityStats {
  IdentityStats({required this.type, required this.country, required this.score});
  final String type;
  final String country;
  final String score;
}

class IdentityLine {
  IdentityLine({
    required this.title,
    required this.status,
    required this.counts,
    required this.ok,
  });
  final String title;
  final String status;
  final String counts;
  final bool ok;
}

class OverallResult {
  OverallResult({required this.kind, required this.result});
  final String kind;
  final String result;
}

class FieldItem {
  FieldItem({required this.id, required this.value, required this.score});
  final String id;
  final String value;
  final String score;
}

class FieldGroup {
  FieldGroup({required this.source, required this.items});
  final String source;
  final List<FieldItem> items;
}

class CheckItem {
  CheckItem({required this.id, required this.result, required this.extra});
  final String id;
  final String result;
  final String extra;
}

class CheckGroup {
  CheckGroup({required this.kind, required this.items});
  final String kind;
  final List<CheckItem> items;
}

class ResultImage {
  ResultImage({
    required this.category,
    required this.source,
    required this.bytes,
  });
  final String category;
  final String source;
  final Uint8List bytes;
}

class Point {
  Point(this.x, this.y);
  final double x;
  final double y;
}

const _longValue = 300;

String _summarizeLong(String value) {
  var type = 'string';
  if (value.startsWith('/9j/') || value.startsWith('data:image/jpeg')) {
    type = 'jpeg';
  } else if (value.startsWith('iVBOR') || value.startsWith('data:image/png')) {
    type = 'png';
  } else if (value.startsWith('R0lGOD') || value.startsWith('data:image/gif')) {
    type = 'gif';
  } else if (value.startsWith('Qk') && value.length > 100) {
    type = 'bmp';
  } else if (RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(value)) {
    type = 'base64';
  }
  return '$type, ${value.length} chars';
}

dynamic _sanitize(dynamic value) {
  if (value is List) return value.map(_sanitize).toList();
  if (value is Map) {
    return value.map((k, v) => MapEntry(k, _sanitize(v)));
  }
  if (value is String && value.length > _longValue) {
    return _summarizeLong(value);
  }
  return value;
}

JsonMap? _jsonObject(Object raw) {
  try {
    final DocResult normalized;
    if (raw is DocResult) {
      normalized = raw;
    } else if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return null;
      normalized = normalizeResult(trimmed);
    } else {
      return null;
    }
    final map = normalized.toJson();
    return map.isEmpty ? null : map;
  } catch (_) {
    return null;
  }
}

String pretty(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '(empty response)';
  try {
    final obj = normalizeResult(trimmed).toJson();
    return const JsonEncoder.withIndent('  ').convert(_sanitize(obj));
  } catch (_) {
    return _summarizeLong(trimmed);
  }
}

String _scoreText(dynamic value) {
  final n = value is num ? value.toDouble() : double.tryParse('$value');
  if (n == null) return '';
  return n.toStringAsFixed(6);
}

JsonMap _document(JsonMap obj) {
  final ident = obj['identity'] ?? obj['document'];
  if (ident is Map) return Map<String, dynamic>.from(ident);
  return {};
}

JsonMap _session(JsonMap obj) {
  final meta = obj['session'] ?? obj['metadata'];
  if (meta is Map) return Map<String, dynamic>.from(meta);
  return {};
}

List<dynamic> _readingsOf(JsonMap obj) {
  final raw = obj['readings'] ?? obj['fields'];
  return raw is List ? raw : const [];
}

List<dynamic> _testsOf(JsonMap obj) {
  final raw = obj['tests'] ?? obj['checks'];
  return raw is List ? raw : const [];
}

String _pick(Map item, List<String> keys, [String fallback = '']) {
  for (final key in keys) {
    final value = item[key];
    if (value is String && value.isNotEmpty) return value;
    if (value != null && value is! String && '$value'.isNotEmpty) return '$value';
  }
  return fallback;
}

String _identClass(Map ident) => _pick(ident, ['class', 'type']);

String _fieldName(Map item) => remapName(_pick(item, ['name', 'id']));

String _originOf(Map item) => remapOrigin(_pick(item, ['origin', 'source'], 'field'));

String _groupOf(Map item) => remapGroup(_pick(item, ['group', 'kind'], 'check'));

String _outcomeOf(Map item) => remapOutcome(_pick(item, ['outcome', 'result'], 'hold'));

String _noteOf(Map item) => _pick(item, ['note', 'reason']);

String _imageName(Map item) => remapName(_pick(item, ['name', 'id'], 'image'));

String _imageData(Map item) => _pick(item, ['data', 'image']);

int? _statusOf(JsonMap obj) {
  final meta = _session(obj);
  if (meta['code'] is num) return (meta['code'] as num).toInt();
  if (meta['status'] is num) return (meta['status'] as num).toInt();
  if (obj['code'] is num) return (obj['code'] as num).toInt();
  return int.tryParse('${meta['code'] ?? meta['status'] ?? obj['code'] ?? ''}');
}

String _messageOf(JsonMap obj) {
  final meta = _session(obj);
  final detail = _pick(meta, ['detail', 'message']);
  if (detail.isNotEmpty) return remapDetail(detail);
  return obj['message'] is String ? remapDetail(obj['message'] as String) : '';
}

String _pageSide(dynamic value) {
  final n = value is num ? value.toInt() : int.tryParse('$value') ?? 0;
  if (n == 0) return 'Front';
  if (n == 1) return 'Back';
  return 'Page $n';
}

String summary(String raw) {
  final obj = _jsonObject(raw);
  if (obj == null) return raw.length > 200 ? raw.substring(0, 200) : raw;
  if (obj['msg'] is String) return obj['msg'] as String;
  final ident = _document(obj);
  final code = _statusOf(obj) ?? 0;
  final message = _messageOf(obj);
  final score = _scoreText(ident['score']).isEmpty ? '—' : _scoreText(ident['score']);
  final title = _identClass(ident);
  return [
    '${code == 0 ? 'ok' : 'failed'} · status=$code${message.isEmpty ? '' : ' · $message'}',
    '${title.isNotEmpty ? title : '—'} · ${ident['country'] is String && (ident['country'] as String).isNotEmpty ? ident['country'] : '—'}',
    'score: $score',
  ].join('\n');
}

IdentityStats identity(String raw) {
  final obj = _jsonObject(raw);
  if (obj == null) return IdentityStats(type: '—', country: '—', score: '—');
  final ident = _document(obj);
  final type = _identClass(ident).isNotEmpty ? _identClass(ident) : '—';
  final country = ident['country'] is String && (ident['country'] as String).isNotEmpty
      ? ident['country'] as String
      : '—';
  final n = num.tryParse('${ident['score']}');
  final score = n == null ? '—' : n.toStringAsFixed(2);
  return IdentityStats(type: type, country: country, score: score);
}

/// Same three-line card as the web `ix-ident` block.
IdentityLine identityLine(String raw) {
  final obj = _jsonObject(raw);
  if (obj == null) {
    return IdentityLine(
      title: '— · — · —',
      status: 'failed · status=— · —',
      counts: '0 fields · 0 checks · 0 pass · 0 fail · 0 skip',
      ok: false,
    );
  }
  final stats = identity(raw);
  final code = _statusOf(obj);
  final ok = code == 0;
  final message = _messageOf(obj).trim();
  final codeText = code == null ? '—' : '$code';
  final fields = _readingsOf(obj);
  final checks = _testsOf(obj);
  var pass = 0;
  var fail = 0;
  for (final item in checks) {
    if (item is! Map) continue;
    final result = _outcomeOf(item);
    if (result == 'pass') pass += 1;
    if (result == 'fail') fail += 1;
  }
  final skip = (checks.length - pass - fail).clamp(0, checks.length);
  return IdentityLine(
    title: '${stats.type} · ${stats.country} · ${stats.score}',
    status: '${ok ? 'ok' : 'failed'} · status=$codeText · ${message.isEmpty ? '—' : message}',
    counts:
        '${fields.length} fields · ${checks.length} checks · $pass pass · $fail fail · $skip skip',
    ok: ok,
  );
}

const _overallKinds = ['validity', 'capture', 'authenticity'];
const _fieldSourceOrder = ['visual', 'zone', 'code'];
const _checkResultRank = {'fail': 0, 'pass': 1, 'hold': 2, 'skip': 2};
const _sourceLabels = {'visual': 'VISUAL', 'zone': 'ZONE', 'code': 'CODE', 'chip': 'CHIP'};
const _kindLabels = {
  'validity': 'Validity',
  'capture': 'Capture',
  'verify': 'Validity',
  'quality': 'Capture',
  'security': 'Liveness',
  'authenticity': 'Liveness',
  'liveness': 'Liveness',
};

String sourceLabel(String source) {
  final key = source.trim().toLowerCase();
  return _sourceLabels[key] ?? (key.isEmpty ? 'FIELD' : key.toUpperCase());
}

String kindLabel(String kind) {
  final key = kind.trim().toLowerCase();
  if (_kindLabels.containsKey(key)) return _kindLabels[key]!;
  if (key.isEmpty) return 'Check';
  return '${key[0].toUpperCase()}${key.substring(1)}';
}

/// Kind-level roll-up: any fail → fail, else any pass → pass, else skip.
List<OverallResult> overallResults(String raw) {
  final obj = _jsonObject(raw);
  final checks = obj != null ? _testsOf(obj) : const [];
  return [
    for (final kind in _overallKinds)
      OverallResult(kind: kind, result: _overallResult(checks, kind)),
  ];
}

String _overallResult(List<dynamic> checks, String kind) {
  var anyPass = false;
  for (final item in checks) {
    if (item is! Map) continue;
    if (_groupOf(item) != kind) continue;
    final result = _outcomeOf(item);
    if (result == 'fail') return 'fail';
    if (result == 'pass') anyPass = true;
  }
  return anyPass ? 'pass' : 'skip';
}

List<FieldGroup> fieldGroups(String raw) {
  final obj = _jsonObject(raw);
  if (obj == null) return [];
  final buckets = <String, List<FieldItem>>{};
  final extra = <String>[];
  for (final item in _readingsOf(obj)) {
    if (item is! Map) continue;
    final value = '${item['value'] ?? ''}';
    if (value.isEmpty || value == 'null') continue;
    final source = _originOf(item);
    buckets.putIfAbsent(source, () {
      if (!_fieldSourceOrder.contains(source)) extra.add(source);
      return <FieldItem>[];
    });
    buckets[source]!.add(FieldItem(
      id: _fieldName(item),
      value: value,
      score: _scoreText(item['score']),
    ));
  }
  return [
    for (final source in [..._fieldSourceOrder, ...extra])
      if ((buckets[source] ?? const []).isNotEmpty)
        FieldGroup(source: source, items: buckets[source]!),
  ];
}

List<CheckGroup> checkGroups(String raw) {
  final obj = _jsonObject(raw);
  final checks = obj != null ? _testsOf(obj) : const [];
  final buckets = <String, List<CheckItem>>{
    for (final kind in _overallKinds) kind: <CheckItem>[],
  };
  final extra = <String>[];
  for (final item in checks) {
    if (item is! Map) continue;
    final kind = _groupOf(item);
    final extraBits = <String>[];
    final reason = _noteOf(item);
    if (reason.isNotEmpty) extraBits.add(reason);
    final score = _scoreText(item['score']);
    if (score.isNotEmpty) extraBits.add(score);
    buckets.putIfAbsent(kind, () {
      extra.add(kind);
      return <CheckItem>[];
    });
    final name = _fieldName(item);
    final page = item['page'];
    final pageSet = <dynamic>{
      for (final c in checks)
        if (c is Map && c['page'] != null) c['page'],
    };
    final checkId = (page != null && (pageSet.length > 1 || (page is num ? page.toInt() : int.tryParse('$page') ?? 0) != 0))
        ? '${_pageSide(page)} · $name'
        : name;
    buckets[kind]!.add(CheckItem(
      id: checkId,
      result: _outcomeOf(item),
      extra: extraBits.join(' · '),
    ));
  }
  return [
    for (final kind in [..._overallKinds, ...extra])
      if ((buckets[kind] ?? const []).isNotEmpty)
        CheckGroup(
          kind: kind,
          items: List<CheckItem>.from(buckets[kind]!)
            ..sort(
              (a, b) => (_checkResultRank[a.result] ?? 9).compareTo(
                _checkResultRank[b.result] ?? 9,
              ),
            ),
        ),
  ];
}

List<FieldRow> fieldRows(String raw) {
  final obj = _jsonObject(raw);
  if (obj == null) return [];
  final out = <FieldRow>[];
  for (final item in _readingsOf(obj)) {
    if (item is! Map) continue;
    final value = '${item['value'] ?? ''}';
    final extra = _scoreText(item['score']);
    out.add(FieldRow(
      key: _fieldName(item),
      value: extra.isEmpty ? value : '$value · $extra',
      source: _originOf(item),
    ));
  }
  return out.where((r) => r.value.isNotEmpty && r.value != 'null').toList();
}

List<SecurityRow> checkRows(String raw) {
  final obj = _jsonObject(raw);
  if (obj == null) return [];
  final out = <SecurityRow>[];
  for (final item in _testsOf(obj)) {
    if (item is! Map) continue;
    var label = _outcomeOf(item);
    final extra = _scoreText(item['score']);
    if (extra.isNotEmpty) label = '$label · $extra';
    final reason = _noteOf(item);
    if (reason.isNotEmpty) label = '$label — $reason';
    out.add(SecurityRow(
      page: _groupOf(item),
      check: _fieldName(item),
      status: label,
    ));
  }
  return out;
}

List<FieldRow> rows(String raw) {
  final obj = _jsonObject(raw);
  if (obj == null) return [];
  final ident = _document(obj);
  final out = <FieldRow>[];
  final identClass = _identClass(ident);
  if (identClass.isNotEmpty) {
    out.add(FieldRow(key: 'class', value: identClass, source: 'identity'));
  }
  if (ident['country'] is String && (ident['country'] as String).isNotEmpty) {
    out.add(FieldRow(key: 'country', value: ident['country'] as String, source: 'identity'));
  }
  final score = _scoreText(ident['score']);
  if (score.isNotEmpty) {
    out.add(FieldRow(key: 'score', value: score, source: 'identity'));
  }
  for (final item in _readingsOf(obj)) {
    if (item is! Map) continue;
    final value = '${item['value'] ?? ''}';
    final extra = _scoreText(item['score']);
    out.add(FieldRow(
      key: _fieldName(item),
      value: extra.isEmpty ? value : '$value · $extra',
      source: _originOf(item),
    ));
  }
  for (final item in _testsOf(obj)) {
    if (item is! Map) continue;
    if (_groupOf(item) == 'authenticity') continue;
    var label = _outcomeOf(item);
    final extra = _scoreText(item['score']);
    if (extra.isNotEmpty) label = '$label · $extra';
    final reason = _noteOf(item);
    if (reason.isNotEmpty) label = '$label — $reason';
    out.add(FieldRow(
      key: _fieldName(item),
      value: label,
      source: _groupOf(item),
    ));
  }
  return out.where((r) => r.value.isNotEmpty && r.value != 'null').toList();
}

List<ResultImage> images(String raw) {
  final obj = _jsonObject(raw);
  if (obj == null || obj['images'] is! List) return [];
  final out = <ResultImage>[];
  final seen = <String>{};
  for (final item in obj['images'] as List) {
    if (item is! Map) continue;
    var b64 = _imageData(item);
    if (b64.length < 32) continue;
    final id = _imageName(item);
    final page = item['page'];
    final key = '$id|${b64.length}:${b64.substring(0, b64.length > 48 ? 48 : b64.length)}';
    if (!seen.add(key)) continue;
    var payload = b64.contains('base64,')
        ? b64.substring(b64.indexOf('base64,') + 7)
        : b64;
    payload = payload.replaceAll(RegExp(r'\s'), '');
    try {
      final bytes = base64Decode(payload);
      if (bytes.isEmpty) continue;
      out.add(ResultImage(
        category: page == null ? id : '$id (page $page)',
        source: '',
        bytes: bytes,
      ));
    } catch (_) {}
  }
  return out;
}

int documentPercent(String raw) {
  final obj = _jsonObject(raw);
  if (obj == null) return 0;
  final ident = _document(obj);
  final rawScore = ident['score'] ?? obj['score'];
  if (rawScore == null) return 0;
  final s = num.tryParse('$rawScore') ?? 0;
  final pct = s <= 1.0 ? s * 100.0 : s;
  return pct.clamp(0, 100).truncate();
}

({double width, double height})? locateImageSize(String raw) {
  final obj = _jsonObject(raw);
  if (obj == null) return null;
  final w = num.tryParse('${obj['_locateImageWidth']}');
  final h = num.tryParse('${obj['_locateImageHeight']}');
  if (w == null || h == null || w <= 0 || h <= 0) return null;
  return (width: w.toDouble(), height: h.toDouble());
}

({double width, double height}) uprightSnapshotSize(
  double width,
  double height,
) {
  if (width > height) {
    return (width: height, height: width);
  }
  return (width: width, height: height);
}

List<Point>? mapUprightCornersToView(
  List<Point> corners,
  double imageW,
  double imageH,
  double viewW,
  double viewH,
) {
  if (corners.length < 4 ||
      imageW <= 1 ||
      imageH <= 1 ||
      viewW <= 1 ||
      viewH <= 1) {
    return null;
  }
  final scale = (viewW / imageW > viewH / imageH)
      ? viewW / imageW
      : viewH / imageH;
  final dx = (viewW - imageW * scale) / 2;
  final dy = (viewH - imageH * scale) / 2;
  return corners
      .map((c) => Point(c.x * scale + dx, (imageH - c.y) * scale + dy))
      .toList();
}

List<Point>? documentCorners(String raw) {
  final obj = _jsonObject(raw);
  if (obj == null || obj['position'] is! Map) return null;
  final pos = Map<String, dynamic>.from(obj['position'] as Map);
  if (pos['corners'] is List && (pos['corners'] as List).length >= 4) {
    final out = <Point>[];
    final corners = pos['corners'] as List;
    for (var i = 0; i < 4; i++) {
      final p = corners[i];
      if (p is! Map) return null;
      final x = num.tryParse('${p['x']}');
      final y = num.tryParse('${p['y']}');
      if (x == null || y == null) return null;
      out.add(Point(x.toDouble(), y.toDouble()));
    }
    return out;
  }
  final l = num.tryParse('${pos['left']}');
  final t = num.tryParse('${pos['top']}');
  final r = num.tryParse('${pos['right']}');
  final b = num.tryParse('${pos['bottom']}');
  if (l == null || t == null || r == null || b == null || r <= l || b <= t) {
    return null;
  }
  return [
    Point(l.toDouble(), t.toDouble()),
    Point(r.toDouble(), t.toDouble()),
    Point(r.toDouble(), b.toDouble()),
    Point(l.toDouble(), b.toDouble()),
  ];
}

String securitySummary(String raw) {
  final obj = _jsonObject(raw);
  if (obj == null) {
    return 'No liveness checks in this response. If you expected checks, this license may not include liveness.';
  }
  final checks = _testsOf(obj);
  var pass = 0;
  var fail = 0;
  var skip = 0;
  var any = false;
  for (final item in checks) {
    if (item is! Map || _groupOf(item) != 'authenticity') continue;
    any = true;
    final result = _outcomeOf(item);
    if (result == 'pass') {
      pass += 1;
    } else if (result == 'fail') {
      fail += 1;
    } else {
      skip += 1;
    }
  }
  if (!any) {
    return 'No liveness checks in this response. If you expected checks, this license may not include liveness.';
  }
  final ident = _document(obj);
  final title = _identClass(ident).isNotEmpty ? _identClass(ident) : 'Document';
  return '$title\n$pass pass · $fail fail · $skip skip';
}

List<SecurityRow> securityRows(String raw) {
  final obj = _jsonObject(raw);
  if (obj == null) return [];
  final out = <SecurityRow>[];
  for (final item in _testsOf(obj)) {
    if (item is! Map || _groupOf(item) != 'authenticity') continue;
    var label = _outcomeOf(item);
    final extra = _scoreText(item['score']);
    if (extra.isNotEmpty) label = '$label · $extra';
    out.add(SecurityRow(
      page: _pageSide(item['page'] ?? 0),
      check: _fieldName(item),
      status: label,
    ));
  }
  return out;
}
