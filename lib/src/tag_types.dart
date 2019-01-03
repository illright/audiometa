import 'dart:typed_data';
import 'dart:io';

import 'exceptions.dart';
import 'id3v2_2_parser.dart';
import 'id3v2_2_frames.dart';


enum ID3 {
  v1, v2_2, v2_3, v2_4
}


class ID3Tag {
  ID3 version;
  Map<String, List<ID3Frame>> frames;

  ID3Tag({this.version, this.frames});
}


abstract class ID3Frame {
  final String label;
  final Uint8List data;

  ID3Frame(this.label, this.data);
}


ID3Tag extractTag(Uint8List data, ID3 tagVersion) {
  if (tagVersion == ID3.v2_2) {
    try {
      return ID3v2_2Parser.parseForward(data);
    } on BadTagException {
      return null;
    }
  }
  return null;
}


void main() {
  var track = File('id3v22-test.mp3');
  extractTag(track.readAsBytesSync(), ID3.v2_2).frames.forEach((k, v) {
    for (var frame in v) {
      print('Frame ${frame.label}');
      if (frame is PlainTextFrame) {
        print('  Value: ${frame.text}');
        if (frame is LangDescTextFrame) {
          print('  Language: ${frame.language}');
          print('  Description: ${frame.description}');
        }
      } else {
        print('  Binary data: ${frame.data}');
      }
    }

  });
}
