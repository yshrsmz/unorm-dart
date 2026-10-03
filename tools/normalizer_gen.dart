import 'dart:collection';
import 'dart:convert';
import 'dart:io';

const debug = true;

const String dataDir = "./data/";

const String unicodeData = "$dataDir/UnicodeData.txt";
const String compositionExclusions = "$dataDir/CompositionExclusions.txt";

const String outputFile = "./lib/src/unormdata.dart";

/// Hangul composition constants
const int sBase = 0xAC00;
const int lBase = 0x1100;
const int vBase = 0x1161;
const int tBase = 0x11A7;
const int lCount = 19;
const int vCount = 21;
const int tCount = 28;
const int nCount = vCount * tCount; // 588
const int sCount = lCount * nCount; // 11172

Future<void> main() async {
  await buildNormalizerData();
}

class _UChar {
  _UChar(this.codepoint);

  final int codepoint;
  bool isCompatibility = false;
  bool isExcluded = false;
  List<int>? decompose;
  int canonicalClass = 0;
  Map<int, int> composeTrie = SplayTreeMap();

  int get flag =>
      canonicalClass | (isCompatibility ? 1 << 8 : 0) | (isExcluded ? 1 << 9 : 0);

  void pack(void Function(int) writeVarint, int previous) {
    final decompose = this.decompose;
    writeVarint(codepoint - previous);
    writeVarint((decompose != null ? 1 : 0) | (flag != 0 ? 2 : 0));
    if (decompose != null) {
      writeVarint(decompose.length);
      decompose.forEach(writeVarint);
    }
    if (flag != 0) writeVarint(flag);
    writeVarint(composeTrie.length);
    composeTrie.forEach((key, value) {
      writeVarint(key);
      writeVarint(value);
    });
  }
}

class _UCharCache {
  final Map<int, _UChar> _cache = SplayTreeMap();

  _UChar getOrCreate(int cp) {
    return _cache.putIfAbsent(cp, () => _UChar(cp));
  }

  // Map literal costs ~1 MB of AOT init code, const string is stored as data
  String toDartAll() {
    final bytes = <int>[];
    void writeVarint(int value) {
      while (value >= 0x80) {
        bytes.add((value & 0x7f) | 0x80);
        value >>= 7;
      }
      bytes.add(value);
    }

    final entries = _cache.values
        .where((uc) =>
            uc.canonicalClass != 0 ||
            uc.isCompatibility ||
            uc.isExcluded ||
            uc.decompose != null ||
            uc.composeTrie.isNotEmpty)
        .toList();
    writeVarint(entries.length);
    int previous = 0;
    for (final uc in entries) {
      uc.pack(writeVarint, previous);
      previous = uc.codepoint;
    }

    final packed = StringBuffer();
    for (final byte in bytes) {
      if (byte >= 0x20 && byte < 0x7f && !r"\'$".contains(String.fromCharCode(byte))) {
        packed.writeCharCode(byte);
      } else {
        packed.write("\\x${byte.toRadixString(16).padLeft(2, '0')}");
      }
    }

    return """
final Map<int, Map<int, List<Object?>>> unormdata = _unpack();

Map<int, Map<int, List<Object?>>> _unpack() {
  const String packed = '$packed';
  int position = 0;
  int readVarint() {
    int value = 0, shift = 0, byte;
    do {
      byte = packed.codeUnitAt(position++);
      value |= (byte & 0x7f) << shift;
      shift += 7;
    } while (byte >= 0x80);
    return value;
  }

  final result = <int, Map<int, List<Object?>>>{};
  int codepoint = 0;
  for (int count = readVarint(); count > 0; count--) {
    codepoint += readVarint();
    final tag = readVarint();
    final decompose =
        tag & 1 != 0 ? List<int>.generate(readVarint(), (_) => readVarint()) : null;
    final flag = tag & 2 != 0 ? readVarint() : null;
    final compose = <int, int>{};
    for (int pairs = readVarint(); pairs > 0; pairs--) {
      final key = readVarint();
      compose[key] = readVarint();
    }
    (result[codepoint & 0xff00] ??= {})[codepoint] = [decompose, flag, compose];
  }
  return result;
}
""";
  }
}

Future<void> buildNormalizerData() async {
  try {
    final cache = _UCharCache();
    readExclusionList(cache, compositionExclusions);
    buildDecompositionTables(cache, unicodeData);
    final file = File(outputFile);
    await file.writeAsString(cache.toDartAll(), encoding: utf8);
    // print("cache: ${cache.cache.keys.toList()}");
  } catch (e) {
    print("Can't load datafile. $e");
  }
}

void readExclusionList(_UCharCache cache, String exclusionListFile) {
  if (debug) print("Reading Exclusions");

  final file = File(exclusionListFile);
  final lines = file.readAsLinesSync();

  for (var line in lines) {
    // read a line, discarding comments and blank lines.
    final comment = line.indexOf('#'); // strip comments
    if (comment != -1) {
      line = line.substring(0, comment);
    }
    if (line.isEmpty) continue; // ignore blanks

    // store -1 in the excluded table for each character hit
    final value = int.parse(line.split(RegExp(r'[^\da-fA-F]'))[0], radix: 16);
    cache.getOrCreate(value).isExcluded = true;

    print("Excluding ${_hex(value)}");
  }

  if (debug) print("Done reading Exclusions");

  // workaround
  cache.getOrCreate(0x0F81).isExcluded = true;
  cache.getOrCreate(0x0F73).isExcluded = true;
  cache.getOrCreate(0x0F75).isExcluded = true;
}

/// Builds a decomposition table from a UnicodeData file
void buildDecompositionTables(_UCharCache cache, String unicodeDataFile) {
  if (debug) print("Reading Unicode Character Database");

  final file = File(unicodeDataFile);
  final lines = file.readAsLinesSync();
  var counter = 0;

  for (var line in lines) {
    // read a line, discarding comments and blank lines
    final comment = line.indexOf('#'); // strip comments
    if (comment != -1) {
      line = line.substring(0, comment);
    }
    if (line.isEmpty) continue;

    if (debug) {
      counter++;
      if ((counter & 0xFF) == 0) {
        print("At: $line");
      }
    }

    // find the values of the particular fields that we need
    // Sample line: 00C0;LATIN ...A GRAVE;Lu;0;L;0041 0300;;;;N;LATIN
    // ... GRAVE;;;00E0;

    final parts = line.split(';');
    final value = int.parse(parts[0], radix: 16); // code
    final uchar = cache.getOrCreate(value);

    if (value == 0x00c0) {
      print("debug: $line");
    }

    // parts[1]: name
    // parts[2]: general category

    // canonical class
    final cc = int.parse(parts[3]);
    if (cc != (cc & 0xFF)) {
      print("Bad canonical class at: $line");
    }
    uchar.canonicalClass = cc;

    // parts[4]: BIDI
    // parts[5]: decomp

    // decomp requires more processing.
    // store whether it is canonical or compatibility.
    // store the decomp in one table, and the reverse mapping (from pairs) in another

    if (parts.length > 5 && parts[5].isNotEmpty) {
      final segment = parts[5];
      final compat = segment.startsWith('<');
      if (compat) {
        uchar.isCompatibility = true;
      }
      final decomp = _fromHex(segment);

      // check consistency: all canon decomps must be singles or pairs!
      if (decomp.length < 1 || (decomp.length > 2 && !compat)) {
        print("Bad decomp at: $line");
      }
      uchar.decompose = decomp;

      // only compositions are canonical pairs
      // skip if script exclusion
      if (!compat && !uchar.isExcluded && decomp.length != 1) {
        // no <decomp> and not excluded and not singleton
        cache.getOrCreate(decomp[0]).composeTrie[decomp[1]] = value;
      } else if (debug) {
        print("Excluding: $decomp");
      }
    }
  }

  if (debug) {
    print(" Done reading Unicode Character Database");
  }
}

/// Utility: Supplies a zero-padded hex representation of an integer (without 0x)
String _hex(int i) {
  final result = (i & 0xFFFFFFFF).toRadixString(16).toUpperCase();
  return "00000000".substring(result.length) + result;
}

/// Utility: Parses a sequence of hex Unicode characters separated by spaces
List<int> _fromHex(String source) {
  final result = <int>[];
  for (var i = 0; i < source.length; i++) {
    final c = source[i];
    switch (c) {
      case ' ':
        continue; // ignore
      case '0':
      case '1':
      case '2':
      case '3':
      case '4':
      case '5':
      case '6':
      case '7':
      case '8':
      case '9':
      case 'A':
      case 'B':
      case 'C':
      case 'D':
      case 'E':
      case 'F':
      case 'a':
      case 'b':
      case 'c':
      case 'd':
      case 'e':
      case 'f':
        final num = source.substring(i).split(RegExp(r'[^\dA-Fa-f]'))[0];
        result.add(int.parse(num, radix: 16));
        i += num.length - 1; // skip rest of number
        break;
      case '<':
        final j = source.indexOf('>', i); // skip <...>
        if (j > 0) {
          i = j;
          break;
        } else {
          throw FormatException("Bad hex value in $source");
        }
      default:
        throw FormatException("Bad hex value in $source");
    }
  }
  return result;
}
