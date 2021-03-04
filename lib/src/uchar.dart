import 'package:unorm_dart/src/unormdata.dart';
import 'package:unorm_dart/src/utils.dart';

final _DEFAULT_FEATURE = [null, 0, Map<int, Object>()];
final _CACHE_THRESHOLD = 10;
final _SBase = 0xAC00;
final _LBase = 0x1100;
final _VBase = 0x1161;
final _TBase = 0x11A7;
final _LCount = 19;
final _VCount = 21;
final _TCount = 28;
final _NCount = _VCount * _TCount;
final _SCount = _LCount * _NCount;

bool _initialized = false;
final Map<int, Object?> _cache = Map();
final List<int> _cacheCounter = <int>[];

void initUCharCache() {
  if (_initialized) {
    return;
  }
  for (int i = 0; i <= 0xFF; i++) {
    _cacheCounter.add(0);
  }
  _initialized = true;
}

typedef NextFunc = UChar? Function(int, bool);

UChar? _fromCache(NextFunc? next, int cp, bool needFeature) {
  UChar? ret = _cache[cp] as UChar?;
  if (ret == null) {
    ret = next!(cp, needFeature);
    if (ret!.feature != null &&
        ++_cacheCounter[(cp >> 8) & 0xFF] > _CACHE_THRESHOLD) {
      _cache[cp] = ret;
    }
  }
  return ret;
}

UChar? _fromData(NextFunc? next, int cp, bool needFeature) {
  final hash = cp & 0xFF00;
  final dunit = unormdata[hash] ?? {};
  final f = dunit[cp];
  return f != null ? UChar(cp, f) : UChar(cp, _DEFAULT_FEATURE);
}

UChar? _fromCpOnly(NextFunc? next, int cp, bool needFeature) {
  return needFeature ? next!(cp, needFeature) : UChar(cp, null);
}

UChar? _fromRuleBasedJamo(NextFunc? next, int cp, bool needFeature) {
  if (cp < _LBase ||
      (_LBase + _LCount <= cp && cp < _SBase) ||
      (_SBase + _SCount < cp)) {
    return next!(cp, needFeature);
  }
  if (_LBase <= cp && cp < _LBase + _LCount) {
    final c = Map<int, Object>();
    final base = (cp - _LBase) * _VCount;
    for (int i = 0; i < _VCount; ++i) {
      c[_VBase + i] = _SBase + _TCount * (i + base);
    }
    return UChar(cp, [null, null, c]);
  }

  final SIndex = cp - _SBase;
  final TIndex = SIndex % _TCount;
  final feature = List<dynamic>.filled(3, null, growable: false);
  if (TIndex != 0) {
    feature[0] = [_SBase + SIndex - TIndex, _TBase + TIndex];
    feature[1] = null;
    feature[2] = null;
  } else {
    feature[0] = [
      _LBase + (SIndex / _NCount).floor(),
      _VBase + ((SIndex % _NCount) / _TCount).floor()
    ];
    feature[1] = null;
    feature[2] = Map<int, int>();
    for (int j = 1; j < _TCount; ++j) {
      feature[2][_TBase + j] = cp + j;
    }
  }
  return UChar(cp, feature);
}

UChar? _fromCpFilter(NextFunc? next, int cp, bool needFeature) {
  return cp < 60 || 13311 < cp && cp < 42607
      ? UChar(cp, _DEFAULT_FEATURE)
      : next!(cp, needFeature);
}

final Function _fromCharCode = reduceRight(
    [_fromCpFilter, _fromCache, _fromCpOnly, _fromRuleBasedJamo, _fromData],
    (next, strategy, int index, List list) {
  return (int cp, bool needFeature) {
    return strategy!(next, cp, needFeature);
  };
}, null);

class UChar {
  final int codepoint;
  List<Object?>? _feature;

  List<Object?>? get feature => _feature;

  UChar(this.codepoint, this._feature);

  void prepareFeature() {
    if (this.feature == null) {
      this._feature = UChar.fromCharCode(this.codepoint, true)!.feature;
    }
  }

  @override
  String toString() {
    if (this.codepoint < 0x10000) {
      return String.fromCharCode(this.codepoint);
    } else {
      final x = this.codepoint - 0x10000;
      return String.fromCharCodes(
          [(x / 0x400).floor() + 0xD800, x % 0x400 + 0xDC00]);
    }
  }

  List<int>? getDecomp() {
    prepareFeature();
    return _feature![0] as List<int>? ?? null;
  }

  bool isCompatibility() {
    prepareFeature();
    final int? feature1 = _feature![1] as int?;
    return feature1 != null && feature1 > 0 && (feature1 & (1 << 8)) > 0;
  }

  bool isExclude() {
    prepareFeature();
    final int? feature1 = _feature![1] as int?;
    return feature1 != null && feature1 > 0 && (feature1 & (1 << 9)) > 0;
  }

  int getCanonicalClass() {
    prepareFeature();
    final int? feature1 = _feature![1] as int?;
    return feature1 != null && feature1 > 0 ? feature1 & 0xFF : 0;
  }

  UChar? getComposite(UChar following) {
    prepareFeature();
    final Map<dynamic, dynamic>? feature2 = _feature![2] as Map<dynamic, dynamic>?;
    if (feature2 == null) {
      return null;
    }
    final int? cp = feature2[following.codepoint];
    return cp != null && cp > 0 ? UChar.fromCharCode(cp, false) : null;
  }

  static UChar? fromCharCode(int cp, bool needFeature) =>
      _fromCharCode(cp, needFeature);

  static bool isHighSurrogate(int cp) {
    return cp >= 0xD800 && cp <= 0xDBFF;
  }

  static bool isLowSurrogate(int cp) {
    return cp >= 0xDC00 && cp <= 0xDFFF;
  }
}
