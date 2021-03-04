import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:test/test.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;

class Parts {
  String line;
  List<List<int>> codes;

  Parts(this.codes, this.line);
}

void main() {
  final String utdata =
      File('./test/NormalizationTest.txt').readAsStringSync(encoding: utf8);

  final List<Parts> tests = [];

  int index = 0;
  utdata.split(RegExp("\r?\n")).forEach((String line) {
    line = line.replaceFirst(RegExp(r"#.*$"), "");
    if (line.indexOf("@") == 0) {
      // title
      return;
    }

    // Columns (c1, c2,...) are separated by semicolons.
    // They have the following meaning: source; NFC; NFD; NFKC; NFKD.
    var parts = line.split(RegExp(r"\s*;\s*"));
    assert(parts.length == 1 || parts.length == 6,
        "There should be five columns, not ${parts.length} -- line ${index}");
    if (parts.length == 1) {
      return;
    }
    parts.removeLast();

    List<List<int>> partsInt = parts
        .map((part) => part
            .split(RegExp(r"\s+"))
            .map((s) => int.parse(s, radix: 16))
            .toList())
        .toList();

    Parts result = Parts(partsInt, "${index}:${line}");
    tests.add(result);

    index++;
  });

  group("normalization ${tests.length} tests", () {
    final bucketSize = 100;
    final int m = (tests.length / bucketSize).ceil();

    for (int i = 0; i < m; i++) {
      int start = i * bucketSize;
      int end = math.min(tests.length, (i + 1) * bucketSize);

      test("${start + 1} - ${end}", () {
        for (int j = start; j < end; j++) {
          doTest(tests[j]);
        }
      });
    }
  });
}

void doTest(Parts parts) {
  var raw = parts.codes.map((codes) => String.fromCharCodes(codes)).toList();

  var nfd = raw.map((s) => unorm.nfd(s)).toList();
  var nfkd = raw.map((s) => unorm.nfkd(s)).toList();
  var nfc = raw.map((s) => unorm.nfc(s)).toList();
  var nfkc = raw.map((s) => unorm.nfkc(s)).toList();

  // NFC
  expect(nfc[0], equals(raw[1]), reason: "${parts.line}: c2 == NFC(c1)");
  expect(nfc[1], equals(raw[1]), reason: "${parts.line}: c2 == NFC(c2)");
  expect(nfc[2], equals(raw[1]), reason: "${parts.line}: c2 == NFC(c3)");
  expect(nfc[3], equals(raw[3]), reason: "${parts.line}: c4 == NFC(c4)");
  expect(nfc[4], equals(raw[3]), reason: "${parts.line}: c4 == NFC(c5)");

  // NFD
  expect(nfd[0], equals(raw[2]), reason: "${parts.line}: c3 == NFD(c1)");
  expect(nfd[1], equals(raw[2]), reason: "${parts.line}: c3 == NFD(c2)");
  expect(nfd[2], equals(raw[2]), reason: "${parts.line}: c3 == NFD(c3)");
  expect(nfd[3], equals(raw[4]), reason: "${parts.line}: c5 == NFD(c4)");
  expect(nfd[4], equals(raw[4]), reason: "${parts.line}: c5 == NFD(c5)");

  // NFKC
  expect(nfkc[0], equals(raw[3]), reason: "${parts.line}: c5 == NFKC(c1)");
  expect(nfkc[1], equals(raw[3]), reason: "${parts.line}: c5 == NFKC(c2)");
  expect(nfkc[2], equals(raw[3]), reason: "${parts.line}: c5 == NFKC(c3)");
  expect(nfkc[3], equals(raw[3]), reason: "${parts.line}: c5 == NFKC(c4)");
  expect(nfkc[4], equals(raw[3]), reason: "${parts.line}: c5 == NFKC(c5)");

  // NFKD
  expect(nfkd[0], equals(raw[4]), reason: "${parts.line}: c5 == NFKD(c1)");
  expect(nfkd[1], equals(raw[4]), reason: "${parts.line}: c5 == NFKD(c2)");
  expect(nfkd[2], equals(raw[4]), reason: "${parts.line}: c5 == NFKD(c3)");
  expect(nfkd[3], equals(raw[4]), reason: "${parts.line}: c5 == NFKD(c4)");
  expect(nfkd[4], equals(raw[4]), reason: "${parts.line}: c5 == NFKD(c5)");
}
