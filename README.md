# unorm_dart

[![Unit Test](https://github.com/yshrsmz/unorm-dart/actions/workflows/pull_request.yml/badge.svg)](https://github.com/yshrsmz/unorm-dart/actions/workflows/pull_request.yml)

Unicode 8.0 Normalization - NFC, NFD, NFKC, NFKD

Dart2 port of [unorm](https://github.com/walling/unorm)

## Functions

This module exports four functions: `nfc`, `nfd`, `nfkc`, and `nfkd`; one for each Unicode normalization. In the browser the functions are exported in the `unorm` global. In CommonJS environments you just require the module. Functions:

- `unorm.nfd(str)` – Canonical Decomposition
- `unorm.nfc(str)` – Canonical Decomposition, followed by Canonical Composition
- `unorm.nfkd(str)` – Compatibility Decomposition
- `unorm.nfkc(str)` – Compatibility Decomposition, followed by Canonical Composition

## Usage

A simple usage example:

```dart
import "package:unorm_dart/unorm_dart.dart" as unorm;

void main() {
  var text = "The \u212B symbol invented by A. J. \u00C5ngstr\u00F6m " +
      "(1814, L\u00F6gd\u00F6, \u2013 1874) denotes the length " +
      "10\u207B\u00B9\u2070 m.";

  var combining = RegExp(r"[\u0300-\u036F]/g");

  print("Regular:  ${text}");
  print("NFC:      ${unorm.nfc(text)}");
  print("NFKC:     ${unorm.nfkc(text)}");
  print("NFKD: *   ${unorm.nfkd(text).replaceAll(combining, "")}");
  print(" * = Combining characters removed from decomposed form.");
}
```

## Generating Unicode data

- [Unicode normalization forms report](http://www.unicode.org/reports/tr15/)
- Unicode data can be found from http://www.unicode.org/Public/UCD/latest/ucd

```shell
dart run tools/normalizer_gen.dart
```


## Features and bugs

Please file feature requests and bugs at the [issue tracker](https://github.com/yshrsmz/unorm-dart).
