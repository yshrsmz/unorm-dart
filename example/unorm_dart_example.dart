import "package:unorm_dart/unorm_dart.dart" as unorm;

void main() {
  print(unorm.nfkd("㍍ガバヴァぱばぐゞちぢ十人十色"));

  var text = "The \u212B symbol invented by A. J. \u00C5ngstr\u00F6m " +
      "(1814, L\u00F6gd\u00F6, \u2013 1874) denotes the length " +
      "10\u207B\u00B9\u2070 m.";

  var combining = RegExp(r"[\u0300-\u036F]/g");

  print("Regular:  ${text}");
  print("NFC:      ${unorm.nfc(text)}");
  print("NFKC:     ${unorm.nfkc(text)}");
  print("NFKD: *   ${unorm.nfkd(text).replaceAll(combining, "")}");
  print(" * = Combining characters removed from decomposed form.");
}
