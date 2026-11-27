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

  group('Hangul syllable boundary', () {
    // Hangul Syllables are U+AC00..U+D7A3 (SBase + SCount is exclusive).
    test('U+AC00 (first syllable) decomposes', () {
      expect(unorm.nfd('\uAC00'), equals('\u1100\u1161'));
      expect(unorm.nfkd('\uAC00'), equals('\u1100\u1161'));
      expect(unorm.nfc('\u1100\u1161'), equals('\uAC00'));
      expect(unorm.nfkc('\u1100\u1161'), equals('\uAC00'));
    });

    test('U+D7A3 (last syllable) decomposes and recomposes', () {
      expect(unorm.nfd('\uD7A3'), equals('\u1112\u1175\u11C2'));
      expect(unorm.nfkd('\uD7A3'), equals('\u1112\u1175\u11C2'));
      expect(unorm.nfc('\uD7A3'), equals('\uD7A3'));
      expect(unorm.nfkc('\uD7A3'), equals('\uD7A3'));
      expect(unorm.nfc('\u1112\u1175\u11C2'), equals('\uD7A3'));
    });

    // https://github.com/yshrsmz/unorm-dart/issues/84
    for (final cp in [0xD7A4, 0xD7A5, 0xD7AF]) {
      final hex = cp.toRadixString(16).toUpperCase();
      test('U+$hex (outside the syllable block) is unchanged', () {
        final s = String.fromCharCode(cp);
        expect(unorm.nfc(s), equals(s));
        expect(unorm.nfd(s), equals(s));
        expect(unorm.nfkc(s), equals(s));
        expect(unorm.nfkd(s), equals(s));
      });
    }
  });
}
