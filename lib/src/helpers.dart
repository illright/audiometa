import 'dart:typed_data';


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
/// Either [end] or [length] should be specified, failure to do so will result in
/// an [ArgumentError].
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
    throw ArgumentError('Either end or length should be specified, not both.');
  }

  if (end != null) {
    length = end - start;
  }

  if (length == null) {
    length = view.lengthInBytes - start;
  }

  if (length > view.lengthInBytes - start) {
    throw RangeError('The specified region is out of the view\'s boundaries.');
  }

  return Uint8List.view(view.buffer, view.offsetInBytes + start, length);
}
