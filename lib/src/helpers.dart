import 'dart:typed_data';
import 'dart:convert';

import 'package:utf/utf.dart';

import 'exceptions.dart';

const iso_8859_1 = 0;
const utf16 = 1;
const utf16be = 2;


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
Uint8List resync(Uint8List data) {
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


/// Binary data parser.
class BinaryParser {
  int cursor;
  Uint8List data;

  /// Creates a parser of the [data], setting the [cursor] at the given byte, 0 by default.
  BinaryParser(this.data, {this.cursor = 0});

  /// Finds the first pair (0x00, 0x00) in the [data], starting from [from]. Returns the index of
  /// the first byte in the pair or -1 if the pair is not found.
  static int findDoubleNull(Uint8List data, {int from = 0}) {
    do {
      from = data.indexOf(0, from) + 1;
    } while (from < data.lengthInBytes && data[from] != 0);

    return from >= data.lengthInBytes ? -1 : from - 1;
  }

  /// Returns the next byte in the [data] buffer, advances the [cursor].
  int getByte() {
    return data[cursor++];
  }

  /// Returns a view of bytes from the current cursor position of length [size], places the
  /// [cursor] [size] bytes further.
  Uint8List getBytes({int size}) {
    Uint8List result = getViewRegion(data, start: cursor, length: size);
    cursor += size;
    return result;
  }

  /// Returns a view of bytes from the current cursor position until the end of the [data] buffer,
  /// places the [cursor] at [data.lengthInBytes].
  Uint8List getBytesUntilEnd() {
    Uint8List result = getViewRegion(data, start: cursor);
    cursor = data.lengthInBytes;
    return result;
  }

  /// Returns a string from the current cursor position with the given [size].
  ///
  /// Places the [cursor] after the last byte of the string.
  /// An [encoding] can be additionally specified to determine how to decode binary data to text.
  /// Encoding is passed as the number according to the ID3v2.4 spec
  String getString({int size, int encoding = iso_8859_1}) {
    String result = decodeByEncodingByte(
      getViewRegion(data, start: cursor, length: size),
      encoding,
    );
    cursor += size;
    return result;
  }

  /// Returns the string from the current cursor position to the next null byte.
  ///
  /// Places the [cursor] after the null character.
  /// An [encoding] can be additionally specified to determine how to decode binary data to text.
  /// Encoding is passed as the number according to the ID3v2.4 spec
  String getStringUntilNull({int encoding = iso_8859_1}) {
    int nullSeparator;
    if (encoding == utf16 || encoding == utf16be) {
      nullSeparator = findDoubleNull(data, from: cursor);
    } else {
      nullSeparator = data.indexOf(0, cursor);
    }

    String result = decodeByEncodingByte(
      getViewRegion(data, start: cursor, end: nullSeparator),
      encoding,
    );
    cursor = nullSeparator + 1;
    if (encoding == utf16 || encoding == utf16be) {
      cursor++;  // The null character takes 2 bytes
    }
    return result;
  }

  /// Returns the string from the current cursor position until the end of the [data] buffer,
  /// places the [cursor] at [data.lengthInBytes].
  ///
  /// An [encoding] can be additionally specified to determine how to decode binary data to text.
  /// Encoding is passed as the number according to the ID3v2.4 spec
  String getStringUntilEnd({int encoding = iso_8859_1}) {
    String result = decodeByEncodingByte(
      getViewRegion(data, start: cursor),
      encoding,
    );
    cursor = data.lengthInBytes;
    return result;
  }

  List<String> getStringsUntilEnd({int encoding}) {
    var result = List<String>();
    int nullSeparator;

    while (hasMoreData()) {
      if (encoding == utf16 || encoding == utf16be) {
        nullSeparator = findDoubleNull(data, from: cursor);
      } else {
        nullSeparator = data.indexOf(0, cursor);
      }
      result.add(
        decodeByEncodingByte(getViewRegion(data, start: cursor, end: nullSeparator), encoding)
      );
      cursor = nullSeparator + 1;
      if (encoding == utf16 || encoding == utf16be) {
        cursor++;
      }
    }
    return result;
  }

  /// Returns an integer from the current cursor position spanning [size] bytes, places the
  /// [cursor] after the last byte of the integer.
  int getInt({int size, bool synchSafe = false}) {
    int result = readInt(data.getRange(cursor, cursor + size), synchSafe: synchSafe);
    cursor += size;
    return result;
  }

  /// Returns an integer from the current cursor position until the end of the [data] buffer,
  /// places the [cursor] at [data.lengthInBytes].
  int getIntUntilEnd() {
    int result = readInt(data.getRange(cursor, data.lengthInBytes));
    cursor = data.lengthInBytes;
    return result;
  }

  /// Peeks into the [data] buffer at the cursor position, does not advance the [cursor].
  int nextByte() {
    return data[cursor];
  }

  /// Whether there's more data to parse. Does not advance the [cursor].
  bool hasMoreData() {
    return cursor != data.lengthInBytes;
  }

  /// Whether the current cursor is further or equal than [size] bytes in the data buffer.
  bool exceeds(int size) {
    return cursor >= size;
  }

  /// Advances the [cursor] [amount] positions.
  void advance(int amount) {
    cursor += amount;
  }
}
