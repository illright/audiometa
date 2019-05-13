import 'dart:typed_data';
import 'dart:io';

import 'exceptions.dart';
import 'helpers.dart';
import 'id3v22_parser.dart';
import 'id3v22_frames.dart' as v22;
import 'id3v23_parser.dart';
import 'id3v23_frames.dart' as v23;
import 'id3v1_parser.dart';
import 'id3v1_frames.dart' as v1;


enum ID3 {
  v1, v1_1, v2_2, v2_3, v2_4
}


abstract class ExtHeader {
  int size;
  int flags;

  ExtHeader(this.size, this.flags);
}


class V23ExtHeader extends ExtHeader {
  int paddingSize;
  int frameCRC;

  V23ExtHeader(int size, int flags, this.paddingSize, this.frameCRC) : super(size, flags);

  factory V23ExtHeader.parse(Uint8List data) {
    var parser = BinaryParser(data);
    int flags = parser.getInt(size: 2);

    if (flags & 0x7FFF != 0) {  // 0x7FFF == 0b01111111_11111111
      throw BadTagDataException('Unknown flags set in the extended header.');
    }
    int paddingSize = parser.getInt(size: 4);
    int frameCRC = null;
    if (flags & 0x8000 != 0) {    // 0x8000 == 0b10000000_00000000
      frameCRC = parser.getInt(size: 4);
    }

    return V23ExtHeader(data.lengthInBytes, flags, paddingSize, frameCRC);
  }
}

class ID3Tag {
  ID3 version;
  Map<String, List<ID3Frame>> frames;
  int flags;
  ExtHeader extHeader;


  ID3Tag({this.version, this.flags, this.extHeader, this.frames});
}


abstract class FrameFlags {
  /// The mapping of a bit responsible for the flag to its data.
  ///
  /// For example, 0b0000_0000_0100_0000 is the key for the __grouping identity__
  /// of an ID3v2.4 frame, the value is the group identifier.
  /// If the flag is not meant to have data attached, its value will be [null].
  /// If the flag is not set, the mapping won't contain such a key.
  Map<int, int> data;

  bool contain(int key);

  /// Initializes the flag storage according the the flag integer.
  ///
  /// Marks presence of flags without data, leaving the data placement to the caller.
  FrameFlags.init(int flagInt);

  operator []=(int key, int value);
}


class V23FrameFlags implements FrameFlags {
  static const tagAlterPreserveBit = 0x8000;    // 0x8000 == 0b1000_0000_0000_0000
  static const fileAlterPreserveBit = 0x4000;   // 0x4000 == 0b0100_0000_0000_0000
  static const readOnlyBit = 0x2000;            // 0x2000 == 0b0010_0000_0000_0000
  static const decompressedSizeBit = 0x80;      //   0x80 ==           0b1000_0000
  static const encryptionMethodBit = 0x40;      //   0x40 ==           0b0100_0000
  static const groupIDBit = 0x20;               //   0x20 ==           0b0010_0000

  Map<int, int> data;

  V23FrameFlags({
    bool tagAlterPreserve = false,
    bool fileAlterPreserve = false,
    bool readOnly = false,
    int decompressedSize,
    int encryptionMethod,
    int groupID,
  }) {
    data = Map<int, int>();
    if (tagAlterPreserve) {
      data[tagAlterPreserveBit] = null;
    }

    if (fileAlterPreserve) {
      data[fileAlterPreserveBit] = null;
    }

    if (readOnly) {
      data[readOnlyBit] = null;
    }

    if (decompressedSize != null) {
      data[decompressedSizeBit] = decompressedSize;
    }

    if (encryptionMethod != null) {
      data[encryptionMethodBit] = encryptionMethod;
    }

    if (groupID != null) {
      data[groupIDBit] = groupID;
    }
  }

  bool contain(int key) {
    return data.containsKey(key);
  }

  /// Initializes the flag storage according the the flag integer.
  ///
  /// Marks presence of flags without data, leaving the data placement to the caller.
  V23FrameFlags.init(int flagInt) {
    data = Map<int, int>();
    for (int flagBit in [tagAlterPreserveBit, fileAlterPreserveBit, readOnlyBit]) {
      if (flagInt & flagBit != 0) {
        data[flagBit] = null;
      }
    }
  }

  operator []=(int key, int value) {
    data[key] = value;
  }
}


abstract class ID3Frame {
  final String label;
  final FrameFlags flags;

  ID3Frame(this.label, {this.flags});
}


/// Frame that mainly contains text.
///
/// This is an interface so it does not refer to any actual frames.
abstract class PlainTextFrame {
  String text;
  int encoding;
}


/// Frame that mainly contains binary data.
///
/// The parsing of that data is currently not in the roadmap for this library, but may come later.
/// This is an interface so it does not refer to any actual frames.
class BinaryFrame {
  Uint8List data;
}


ID3Tag extractTag(Uint8List data, ID3 tagVersion) {
  try {
    switch (tagVersion) {
      case ID3.v1:
        return ID3v1Parser.parseForward(data, start: data.lengthInBytes - 128);
      case ID3.v1_1:
        return ID3v1Parser.parseForward(data, start: data.lengthInBytes - 128, v1_1: true);
      case ID3.v2_2:
        return ID3v22Parser.parseForward(data);
      case ID3.v2_3:
        return ID3v23Parser.parseForward(data);
      default:
        return null;
    }
  } on BadTagException {
    return null;
  }
}

void main() {
  var track = File('id3v23-test.mp3');
  extractTag(track.readAsBytesSync(), ID3.v1_1).frames.forEach((k, v) {
    for (var frame in v) {
      print('Frame ${frame.label}');
      if (frame is v1.TextFrame) {
        print('  Value: ${frame.text}');
        /*if (frame is v23.LangDescTextFrame) {
          print('  Language: ${frame.language}');
          print('  Description: ${frame.description}');
          print('  Encoding: ${frame.encoding}');
        }*/
      } else if (frame is v1.ByteFrame) {
        print('  Value: ${frame.value}');
        if (frame.label == 'Genre') {
          print('  Actual genre: ${v1.genreNames[frame.value]}');
        }
      }
    }
  });
}
