import 'package:matcher/matcher.dart';
import 'package:test/test.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;

void main() {
  group('simple example', () {
    setUp(() {});

    test('äiti', () {
      String str = 'äiti';

      expect(unorm.nfc(str), equals('\u00e4\u0069\u0074\u0069'));
      expect(unorm.nfd(str), equals('\u0061\u0308\u0069\u0074\u0069'));
      expect(unorm.nfkc(str), equals('\u00e4\u0069\u0074\u0069'));
      expect(unorm.nfkd(str), equals('\u0061\u0308\u0069\u0074\u0069'));
    });
  });
}
