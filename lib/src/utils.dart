dynamic reduceRight(List list, fn(prev, curr, int index, List list),
    [initialValue]) {
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

List<T?> splice<T>(List<T?> list, int index,
    [num howMany = 0, dynamic elements]) {
  var endIndex = index + howMany.truncate();
  list.removeRange(index, endIndex >= list.length ? list.length : endIndex);
  if (elements != null) {
    List<T?> el = elements is List ? elements as List<T?> : [elements];
    list.insertAll(index, el);
  }

  return list;
}
