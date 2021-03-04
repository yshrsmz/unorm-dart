import 'package:unorm_dart/src/iterator.dart';
import 'package:unorm_dart/src/recursive_decomposite_iterator.dart';
import 'package:unorm_dart/src/uchar.dart';
import 'package:unorm_dart/src/utils.dart';

class DecompositeIterator implements UnormIterator {
  final RecursiveDecompositeIterator _iterator;
  List<UChar> _resultBuffer;

  DecompositeIterator(this._iterator) : this._resultBuffer = [];

  @override
  UChar? next() {
    int cc;
    if (_resultBuffer.isEmpty) {
      do {
        UChar? uchar = _iterator.next();
        if (uchar == null) {
          break;
        }

        cc = uchar.getCanonicalClass();
        int inspt = _resultBuffer.length;
        if (cc != 0) {
          for (; inspt > 0; --inspt) {
            UChar uchar2 = _resultBuffer[inspt - 1];
            int cc2 = uchar2.getCanonicalClass();
            if (cc2 <= cc) {
              break;
            }
          }
        }
        splice<UChar>(_resultBuffer, inspt, 0, uchar);
      } while (cc != 0);
    }
    return _resultBuffer.isEmpty ? null : _resultBuffer.removeAt(0);
  }
}
