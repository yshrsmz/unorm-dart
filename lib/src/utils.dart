import 'package:unorm_dart/src/uchar.dart';

typedef CurrFunc = UChar Function(NextFunc?, int, bool);

Function reduceRight(
  List<UChar Function(NextFunc?, int, bool)> list,
  NextFunc Function(NextFunc? prev, CurrFunc? curr, int index, List list) fn,
    [Function? initialValue]) {
  var length = list.length;
  var index = length - 1;
  var value;
  var isValueSet = false;
  if (1 < list.length) {
    value = initialValue;
    isValueSet = true;
  }
  for (; -1 < index; --index) {
    if (isValueSet) {
      value = fn(value, list[index], index, list);
    } else {
      value = list[index];
      isValueSet = true;
    }
  }
  if (!isValueSet) {
    throw new TypeError(); //'Reduce of empty array with no initial value'
  }
  return value;
}

List<T> splice<T>(List<T> list, int index, [num howMany = 0, T? element]) {
  var endIndex = index + howMany.truncate();
  list.removeRange(index, endIndex >= list.length ? list.length : endIndex);
  if (element != null) {
    list.insertAll(index, [element]);
  }
  return list;
}
