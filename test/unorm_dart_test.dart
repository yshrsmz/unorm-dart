import 'package:matcher/matcher.dart';
import 'package:test/test.dart';
import 'package:unorm_dart/unorm_dart.dart';

void main() {
  group('simple example', () {
    setUp(() {});

    test('äiti', () {
      String str = 'äiti';

      expect(Unorm.nfc(str), equals('\u00e4\u0069\u0074\u0069'));
      expect(Unorm.nfd(str), equals('\u0061\u0308\u0069\u0074\u0069'));
      expect(Unorm.nfkc(str), equals('\u00e4\u0069\u0074\u0069'));
      expect(Unorm.nfkd(str), equals('\u0061\u0308\u0069\u0074\u0069'));
    });
  });
}
