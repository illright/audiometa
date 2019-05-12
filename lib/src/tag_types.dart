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

  FrameFlags.init(int flagInt);

  operator []=(int key, int value);
}


class V23FrameFlags implements FrameFlags {
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
      data[0x8000] = null;  // 0x8000 == 0b1000_0000_0000_0000
    }

    if (fileAlterPreserve) {
      data[0x4000] = null;  // 0x4000 == 0b0100_0000_0000_0000
    }

    if (readOnly) {
      data[0x2000] = null;  // 0x2000 == 0b0010_0000_0000_0000
    }

    if (decompressedSize != null) {
      data[0x80] = decompressedSize;  // 0x80 == 0b1000_0000
    }

    if (encryptionMethod != null) {
      data[0x40] = encryptionMethod;  // 0x40 == 0b0100_0000
    }

    if (groupID != null) {
      data[0x20] = groupID;  // 0x20 == 0b0010_0000
    }
  }

  bool contain(int key) {
    return data.containsKey(key);
  }

  V23FrameFlags.init(int flagInt) {
    data = Map<int, int>();
    for (int flagBit in [0x8000, 0x4000, 0x2000]) {
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
