import 'package:unorm_dart/src/iterator.dart';
import 'package:unorm_dart/src/uchar.dart';
import 'package:unorm_dart/src/uchar_iterator.dart';

class RecursiveDecompositeIterator implements UnormIterator {
  final UCharIterator _iterator;
  final bool _canonical;
  List<UChar> _resultBuffer;

  RecursiveDecompositeIterator(this._iterator, this._canonical)
      : this._resultBuffer = [];

  List<UChar> _recursiveDecompose(bool canonical, UChar uchar) {
    final decomp = uchar.getDecomp();
    if (decomp != null && !(canonical && uchar.isCompatibility())) {
      final ret = <UChar>[];
      for (int i = 0; i < decomp.length; ++i) {
        final a = _recursiveDecompose(
            canonical, UChar.fromCharCode(decomp[i], false)!);
        ret.addAll(a);
      }
      return ret;
    } else {
      return [uchar];
    }
  }

  @override
  UChar? next() {
    if (_resultBuffer.isEmpty) {
      final uchar = _iterator.next();
      if (uchar == null) {
        return null;
      }
      _resultBuffer = _recursiveDecompose(_canonical, uchar);
    }
    return _resultBuffer.removeAt(0);
  }
}
