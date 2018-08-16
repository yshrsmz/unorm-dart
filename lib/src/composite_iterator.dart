import 'package:unorm_dart/src/decomposite_iterator.dart';
import 'package:unorm_dart/src/iterator.dart';
import 'package:unorm_dart/src/uchar.dart';

class CompositeIterator implements UnormIterator {
  final DecompositeIterator _iterator;
  List<UChar> _processBuffer;
  List<UChar> _resultBuffer;
  int _lastClass;

  CompositeIterator(this._iterator)
      : _processBuffer = [],
        _resultBuffer = [],
        _lastClass = -1;

  @override
  UChar next() {
    while (_resultBuffer.isEmpty) {
      UChar uchar = _iterator.next();
      if (uchar == null) {
        _resultBuffer = _processBuffer;
        _processBuffer = [];
        break;
      }
      if (_processBuffer.isEmpty) {
        _lastClass = uchar.getCanonicalClass();
        _processBuffer.add(uchar);
      } else {
        UChar starter = _processBuffer[0];
        UChar composite = starter.getComposite(uchar);
        int cc = uchar.getCanonicalClass();

        if (composite != null && (_lastClass < cc || _lastClass == 0)) {
          _processBuffer[0] = composite;
        } else {
          if (cc == 0) {
            _resultBuffer = _processBuffer;
            _processBuffer = [];
          }
          _lastClass = cc;
          _processBuffer.add(uchar);
        }
      }
    }
    return _resultBuffer.isEmpty ? null : _resultBuffer.removeAt(0);
  }
}
