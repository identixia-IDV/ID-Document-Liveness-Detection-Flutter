import 'dart:convert';

import 'package:document_reader_sdk/document_reader_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

const golden = '''
{
  "identity": {"class": "Passport", "country": "UTO", "score": 0.91},
  "readings": [
    {"name": "familyName", "value": "DOE", "origin": "visual", "score": 0.97},
    {"name": "firstNames", "value": "JOHN", "origin": "visual", "score": 0.96},
    {"name": "docNumber", "value": "123456789", "origin": "zone", "score": 0.99}
  ],
  "tests": [
    {"name": "expiry", "group": "validity", "outcome": "pass"},
    {"name": "focus", "group": "capture", "outcome": "pass", "score": 0.9},
    {"name": "foilCheck", "group": "authenticity", "page": 0, "outcome": "pass", "score": 0.88}
  ],
  "images": [
    {"name": "face", "page": 0, "data": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="}
  ],
  "session": {
    "jobId": "identixia_0123456789abcdef0123456789abcdef",
    "code": 0,
    "detail": "ready",
    "at": "2026-09-14T00:55:12Z"
  }
}
''';

void main() {
  test('identityLine matches the web document card', () {
    final line = identityLine(golden);
    expect(line.title, 'Passport · UTO · 0.91');
    expect(line.status, 'ok · status=0 · ready');
    expect(line.counts, '3 fields · 3 checks · 3 pass · 0 fail · 0 skip');
    expect(line.ok, isTrue);
  });

  test('overallResults rolls up each kind', () {
    final rows = overallResults(golden);
    expect(rows.map((r) => '${r.kind}:${r.result}').toList(), [
      'validity:pass',
      'capture:pass',
      'authenticity:pass',
    ]);
    final failJson = jsonDecode(golden) as Map<String, dynamic>;
    (failJson['tests'] as List).add({'name': 'expiry2', 'group': 'validity', 'outcome': 'fail'});
    (failJson['tests'] as List).add({'name': 'glare', 'group': 'capture', 'outcome': 'hold'});
    final failed = overallResults(jsonEncode(failJson));
    expect(failed.map((r) => '${r.kind}:${r.result}').toList(), [
      'validity:fail',
      'capture:pass',
      'authenticity:pass',
    ]);
  });

  test('fieldGroups orders visual then zone', () {
    final groups = fieldGroups(golden);
    expect(groups.map((g) => g.source).toList(), ['visual', 'zone']);
    expect(groups[0].items.map((i) => i.id).toList(), ['familyName', 'firstNames']);
    expect(groups[1].items.single.id, 'docNumber');
    expect(groups[0].items.first.value, 'DOE');
    expect(groups[0].items.first.score, isNotEmpty);
  });

  test('customer-facing labels never say Security or Authenticity', () {
    expect(sourceLabel('visual'), 'VISUAL');
    expect(sourceLabel('zone'), 'ZONE');
    expect(sourceLabel('code'), 'CODE');
    expect(kindLabel('validity'), 'Validity');
    expect(kindLabel('capture'), 'Capture');
    expect(kindLabel('security'), 'Liveness');
    expect(kindLabel('authenticity'), 'Liveness');
  });

  test('checkGroups orders kinds and fails first', () {
    final failJson = jsonDecode(golden) as Map<String, dynamic>;
    (failJson['tests'] as List).add({
      'name': 'expiry2',
      'group': 'validity',
      'outcome': 'fail',
      'note': 'expired',
    });
    (failJson['tests'] as List).add({'name': 'glare', 'group': 'capture', 'outcome': 'hold'});
    final groups = checkGroups(jsonEncode(failJson));
    expect(groups.map((g) => g.kind).toList(), ['validity', 'capture', 'authenticity']);
    expect(groups[0].items.map((i) => i.id).toList(), ['expiry2', 'expiry']);
    expect(groups[0].items.first.result, 'fail');
    expect(groups[0].items.first.extra, 'expired');
    expect(groups[1].items.map((i) => i.id).toList(), ['focus', 'glare']);
  });

  group('normalizeResult customer JSON', () {
    test('passes through session and the four result keys', () {
      final out = normalizeResult(golden);
      expect(out.code, 0);
      expect(out.message, 'ready');
      expect(out.identity?.klass, 'Passport');
      expect(out.readings.first.name, 'familyName');
      expect(out.readings.first.origin, 'visual');
      expect(out.tests.where((c) => c.group == 'authenticity').first.name, 'foilCheck');
      final json = out.toJson();
      expect(json.containsKey('documentName'), isFalse);
      expect(json.containsKey('ocr'), isFalse);
      expect(json.containsKey('security'), isFalse);
      expect(json.containsKey('api'), isFalse);
    });

    test('normalizeResultJson round-trips customer JSON', () {
      final again = jsonDecode(normalizeResultJson(golden)) as Map<String, dynamic>;
      expect(
        again.keys.toSet().difference({'session', 'identity', 'readings', 'tests', 'images'}),
        isEmpty,
      );
      expect(again['identity']['class'], 'Passport');
    });

    test('extractImageQualityChecks reads capture rows', () {
      final out = normalizeResult(golden);
      final checks = extractImageQualityChecks(out.tests.map((e) => e.toJson()).toList());
      expect(checks['focus'], 0.9);
    });
  });
}
