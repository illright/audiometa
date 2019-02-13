import 'dart:typed_data';

import 'tag_types.dart';
import 'exceptions.dart';
import 'helpers.dart';
import 'id3v1_frames.dart';


class ID3v1Parser {
  static ID3Tag parseForward(Uint8List data, {int start = 0, bool v1_1 = false}) {
    // Informal spec here: http://id3.org/id3v2-00
    var parser = BinaryParser(data, cursor: start);
    // The "TAG" identifier
    if (!(
         parser.getByte() == 0x54  // "T"
      && parser.getByte() == 0x41  // "A"
      && parser.getByte() == 0x47  // "G"
    ))
      throw BadTagException('Missing "TAG" identifier');

    // Frames
    var frames = Map<String, List<ID3Frame>>();

    frames['Songname'] = [
      TextFrame(label: 'Songname', text: parser.getString(size: 30, stripNull: true))
    ];
    frames['Artist'] = [
      TextFrame(label: 'Artist', text: parser.getString(size: 30, stripNull: true))
    ];
    frames['Album'] = [
      TextFrame(label: 'Album', text: parser.getString(size: 30, stripNull: true))
    ];
    frames['Year'] = [
      TextFrame(label: 'Year', text: parser.getString(size: 4, stripNull: true))
    ];
    frames['Comment'] = [
      TextFrame(label: 'Comment', text: parser.getString(size: v1_1 ? 28 : 30, stripNull: true))
    ];
    if (v1_1) {
      if (parser.getByte() == 0) {
        frames['Track number'] = [ByteFrame(label: 'Track number', value: parser.getByte())];
      }
    }
    frames['Genre'] = [ByteFrame(label: 'Genre', value: parser.getByte())];

    return ID3Tag(
      version: v1_1 ? ID3.v1_1 : ID3.v1,
      frames: frames,
    );
  }
}
