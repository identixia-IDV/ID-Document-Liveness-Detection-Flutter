import 'package:document_reader_sdk_example/core/utils/result_parser.dart';
import 'package:flutter_test/flutter_test.dart';

const golden = '''
{
  "identity": {"class": "Passport", "country": "UTO", "score": 0.91},
  "readings": [
    {"name": "familyName", "value": "DOE", "origin": "visual", "score": 0.97},
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
  "session": {"code": 0, "detail": "ready"}
}
''';

String? rowValue(String raw, String key) {
  for (final r in rows(raw)) {
    if (r.key == key) return r.value;
  }
  return null;
}

void main() {
  group('result_parser customer JSON', () {
    test('rows and summary read identity + readings + tests', () {
      expect(rowValue(golden, 'class'), 'Passport');
      expect(rowValue(golden, 'familyName'), contains('DOE'));
      expect(rows(golden).firstWhere((r) => r.key == 'familyName').source, 'visual');
      expect(rows(golden).firstWhere((r) => r.key == 'expiry').source, 'validity');
      expect(summary(golden), contains('Passport'));
      expect(rows(golden).any((r) => r.key == 'foilCheck'), isFalse);
    });

    test('liveness tab reads group=authenticity', () {
      expect(securitySummary(golden), contains('Passport'));
      final parsed = securityRows(golden);
      expect(parsed.single.page, 'Front');
      expect(parsed.single.check, 'foilCheck');
      expect(parsed.single.status, contains('pass'));
    });

    test('explains missing liveness when the payload has none', () {
      expect(
        securitySummary('{"session":{"code":0,"detail":"ready"},"identity":{},"readings":[],"tests":[],"images":[]}'),
        contains('this license may not include liveness'),
      );
      expect(
        securityRows('{"session":{"code":0,"detail":"ready"},"identity":{},"readings":[],"tests":[],"images":[]}'),
        isEmpty,
      );
    });

    test('images render without a native library', () {
      expect(images(golden), isNotEmpty);
      expect(images(golden).first.category, contains('face'));
    });
  });
}
