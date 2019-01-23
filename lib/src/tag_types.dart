import 'dart:typed_data';
import 'dart:io';

import 'exceptions.dart';
import 'helpers.dart';
import 'id3v22_parser.dart';
import 'id3v22_frames.dart' as v22;
import 'id3v23_parser.dart';
import 'id3v23_frames.dart' as v23;


enum ID3 {
  v1, v2_2, v2_3, v2_4
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
    int size = readInt(data.getRange(0, 4));
    int flags = readInt(data.getRange(4, 6));

    if (flags & 0x7FFF != 0) {  // 0x7FFF == 0b01111111_11111111
      throw BadTagDataException('Unknown flags set in the extended header.');
    }
    int paddingSize = readInt(data.getRange(6, 10));
    int frameCRC = null;
    if (flags & 0x8000 != 0) {    // 0x8000 == 0b10000000_00000000
      frameCRC = readInt(data.getRange(10, 14));
    }

    return V23ExtHeader(size, flags, paddingSize, frameCRC);
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

  void init(int flagBit);

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

  void init(int flagInt) {
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
  if (tagVersion == ID3.v2_2) {
    try {
      return ID3v22Parser.parseForward(data);
    } on BadTagException {
      return null;
    }
  }
  if (tagVersion == ID3.v2_3) {
    try {
      return ID3v23Parser.parseForward(data);
    } on BadTagException {
      return null;
    }
  }
  return null;
}

void main() {
  var track = File('id3v23-test.mp3');
  extractTag(track.readAsBytesSync(), ID3.v2_3).frames.forEach((k, v) {
    for (var frame in v) {
      print('Frame ${frame.label}');
      if (frame is v23.PlainTextFrame) {
        print('  Value: ${(frame as v23.PlainTextFrame).text}');
        if (frame is v23.LangDescTextFrame) {
          print('  Language: ${frame.language}');
          print('  Description: ${frame.description}');
          print('  Encoding: ${frame.encoding}');
        }
      }
    }
  });
}
