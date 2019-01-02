import 'dart:typed_data';
import 'dart:io';

import 'helpers.dart';
import 'exceptions.dart';
import 'id3v2_2_parser.dart';
import 'id3v2_2_frames.dart';


enum ID3 {
  v1, v2_2, v2_3, v2_4
}


class ID3Tag {
  ID3 version;
  List<ID3Frame> frames;
  bool unsync;

  ID3Tag({this.version, this.frames, this.unsync});
}


abstract class ID3Frame {
  final String label;
  final Uint8List data;

  ID3Frame(this.label, this.data);
}


bool isID3v2Header(Iterable<int> data) {
  Iterator<int> iter = data.iterator;
  return (
       next(iter) == 0x49  // "I"
    && next(iter) == 0x44  // "D"
    && next(iter) == 0x33  // "3"
    // Version
    && next(iter) < 0xFF
    && next(iter) < 0xFF
    // Flags
    && next(iter) & 0xF == 0x0
    // Tag size
    && next(iter) < 0x80
    && next(iter) < 0x80
    && next(iter) < 0x80
    && next(iter) < 0x80
  );
}


bool isID3v2Footer(Iterable<int> data) {
  Iterator<int> iter = data.iterator;
  return (
       next(iter) == 0x33  // "3"
    && next(iter) == 0x44  // "D"
    && next(iter) == 0x49  // "I"
    // Version
    && next(iter) < 0xFF
    && next(iter) < 0xFF
    // Flags
    && next(iter) & 0xF == 0x0
    // Tag size
    && next(iter) < 0x80
    && next(iter) < 0x80
    && next(iter) < 0x80
    && next(iter) < 0x80
  );
}


ID3Tag extractTag(Uint8List data, ID3 tagVersion) {
  if (tagVersion == ID3.v2_2) {
    try {
      return ID3v2_2Parser.parseForwardFrom(data, start: 0);
    } on BadTagException {
      return null;
    }
  }
  return null;
}


void main() {
  var track = File('id3v22-test.mp3');
  extractTag(track.readAsBytesSync(), ID3.v2_2).frames.forEach((k) {
    print('Frame ${k.label}');
    if (k is PlainTextFrame) {
      print('  Value: ${k.text}');
      if (k is LangDescTextFrame) {
        print('  Language: ${k.language}');
        print('  Description: ${k.description}');
      }
    } else {
      print('  Binary data: ${k.data}');
    }
  });

  //print(isID3v2Header(Uint8List.fromList([0x49, 0x44, 0x33, 0x33, 0x33, 0x33, 33, 0x81, 33, 33])));
}
