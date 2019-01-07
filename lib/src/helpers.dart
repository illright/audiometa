import 'dart:typed_data';
import 'dart:convert';

import 'package:utf/utf.dart';

import 'exceptions.dart';


/// Returns an integer that is encoded over the [data] bytes.
///
/// If [synchSafe] is true, the integer will be read as a synch-safe integer.
int readInt(Iterable<int> data, {bool synchSafe = false}) {
  int result = 0;
  for (var i in data) {
    result <<= synchSafe ? 7 : 8;
    result |= i;
  }
  return result;
}


/// Get a region of a Uint8List view, [start] inclusive, [end] exclusive.
///
/// If no [end] or [length] is specified, the region is assumed to go until the end of the view.
/// Parameters [end] and [length] are mutually exclusive, specifying both will result in
/// an [ArgumentError]. If the specified region exceeds the boundaries of the view, a [RangeError]
/// is thrown.
///
/// Example usage:
/// ```dart
/// var list = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
/// var view = Uint8List.view(list.buffer, 1, 5);
/// print(view);  // [2, 3, 4, 5, 6]
/// print(getViewRegion(view, start: 2, end: 4));  // [4, 5]
/// print(getViewRegion(view, start: 2, length: 4));  // [4, 5, 6, 7]
/// print(getViewRegion(view, start: 2, length: 12));  // RangeError
/// ```
Uint8List getViewRegion(Uint8List view, {int start = 0, int end, int length}) {
  if (end != null && length != null) {
    throw ArgumentError('Parameters `end` and `length` are mutually exclusive.');
  }

  if (end != null) {
    length = end - start;
  }

  if (length == null) {
    length = view.lengthInBytes - start;
  }

  if (length > view.lengthInBytes - start || start < 0) {
    throw RangeError('The specified region is out of the view\'s boundaries.');
  }

  return Uint8List.view(view.buffer, view.offsetInBytes + start, length);
}


/// Removes unsynchronization changes from [data].
///
/// According to the spec of the unsynchronization scheme, it's required and sufficient to
/// remove every 0x00 that immediately follows 0xFF.
Uint8List removeUnsync(Uint8List data) {
  var result = Uint8List(data.lengthInBytes);
  int lastByte;
  int cursor = 0;
  for (int byte in data) {
    if (lastByte != 0xFF || byte != 0x00) {
      result[cursor++] = byte;
    }
    lastByte = byte;
  }
  return result;
}


/// Decodes binary [data] with the encoding that's specified in the [encodingByte].
///
/// According to the ID3v2 spec, here's the mapping of values to encodings:
/// encodingByte = 0 => ISO-8859-1 is used
/// encodingByte = 1 => UTF-16 is used
/// encodingByte = 2 => UTF-16BE is used
/// encodingByte = 3 => UTF-8 is used
String decodeByEncodingByte(Uint8List data, int encodingByte) {
  switch (encodingByte) {
    case 0x0:
      return latin1.decode(data);
    case 0x1:
      return decodeUtf16(data);
    case 0x2:
      return decodeUtf16be(data);
    case 0x3:
      return decodeUtf8(data);
    default:
      throw BadTagDataException(
        'Expected encoding byte to be in range [0:3], $encodingByte found.'
      );
  }
}
