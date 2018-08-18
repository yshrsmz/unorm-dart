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
  throw ArgumentError.value(mode, "mode", "Invalid normalization mode");
}

String _normalize(_NormalizeMode mode, String str) {
  initUCharCache();
  UnormIterator iterator = _createIterator(mode, str);
  String ret = "";
  UChar uchar;
  while ((uchar = iterator.next()) != null) {
    ret += uchar.toString();
  }
  return ret;
}

String nfd(String str) => _normalize(_NormalizeMode.NFD, str);

String nfkd(String str) => _normalize(_NormalizeMode.NFKD, str);

String nfc(String str) => _normalize(_NormalizeMode.NFC, str);

String nfkc(String str) => _normalize(_NormalizeMode.NFKC, str);
