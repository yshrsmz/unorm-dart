import 'package:unorm_dart/src/iterator.dart';
import 'package:unorm_dart/src/uchar.dart';

class UCharIterator implements UnormIterator {
  String _str;
  int _cursor = 0;

  UCharIterator(this._str);

  @override
  UChar next() {
    if (_str != null && this._cursor < this._str.length) {
      int cp = _str.codeUnitAt(_cursor++);
      int d;
      if (UChar.isHighSurrogate(cp) &&
          _cursor < _str.length &&
          UChar.isLowSurrogate((d = _str.codeUnitAt(_cursor)))) {
        cp = (cp - 0xD800) * 0x400 + (d - 0xDC00) + 0x10000;
        ++_cursor;
      }
      return UChar.fromCharCode(cp, false);
    } else {
      _str = null;
      return null;
    }
  }
}
