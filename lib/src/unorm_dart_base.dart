import 'package:unorm_dart/src/composite_iterator.dart';
import 'package:unorm_dart/src/decomposite_iterator.dart';
import 'package:unorm_dart/src/iterator.dart';
import 'package:unorm_dart/src/recursive_decomposite_iterator.dart';
import 'package:unorm_dart/src/uchar.dart';
import 'package:unorm_dart/src/uchar_iterator.dart';

enum _NormalizeMode { NFD, NFKD, NFC, NFKC }

UnormIterator _createIterator(_NormalizeMode mode, String str) {
  switch (mode) {
    case _NormalizeMode.NFD:
      return DecompositeIterator(
          RecursiveDecompositeIterator(UCharIterator(str), true));
    case _NormalizeMode.NFKD:
      return DecompositeIterator(
          RecursiveDecompositeIterator(UCharIterator(str), false));
    case _NormalizeMode.NFC:
      return CompositeIterator(DecompositeIterator(
          RecursiveDecompositeIterator(UCharIterator(str), true)));
    case _NormalizeMode.NFKC:
      return CompositeIterator(DecompositeIterator(
          RecursiveDecompositeIterator(UCharIterator(str), false)));
  }
}

String _normalize(_NormalizeMode mode, String str) {
  initUCharCache();
  UnormIterator iterator = _createIterator(mode, str);
  StringBuffer ret = StringBuffer();
  UChar? uchar;
  while ((uchar = iterator.next()) != null) {
    ret.writeCharCode(uchar!.codepoint);
  }
  return ret.toString();
}

/// Normalizes provided [str] with Canonical Decomposition.
String nfd(String str) => _normalize(_NormalizeMode.NFD, str);

/// Normalizes provided [str] with Compatibility Decomposition.
String nfkd(String str) => _normalize(_NormalizeMode.NFKD, str);

/// Normalizes provided [str] with Canonical Decomposition, followed by Canonical Composition.
String nfc(String str) => _normalize(_NormalizeMode.NFC, str);

/// Normalizes provided [str] with Compatibility Decomposition, followed by Canonical Composition.
String nfkc(String str) => _normalize(_NormalizeMode.NFKC, str);
