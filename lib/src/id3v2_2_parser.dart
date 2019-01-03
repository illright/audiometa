import 'dart:typed_data';

import 'tag_types.dart';
import 'exceptions.dart';
import 'helpers.dart';
import 'id3v2_2_frames.dart';


final frameByID = <String, ID3Frame Function(String, Uint8List)>{
  'UFI': (label, data) => UFI(label, data),
  'IPL': (label, data) => IPL(label, data),
  'MLL': (label, data) => MLL(label, data),
  'SLT': (label, data) => SLT(label, data),
  'RVA': (label, data) => RVA(label, data),
  'EQU': (label, data) => EQU(label, data),
  'REV': (label, data) => REV(label, data),
  'PIC': (label, data) => PIC(label, data),
  'GEO': (label, data) => GEO(label, data),
  'CNT': (label, data) => CNT(label, data),
  'POP': (label, data) => POP(label, data),
  'BUF': (label, data) => BUF(label, data),
  'CRM': (label, data) => CRM(label, data),
  'CRA': (label, data) => CRA(label, data),
  'LNK': (label, data) => LNK(label, data),
  'TT1': (label, data) => TextFrame(label, data),
  'TT2': (label, data) => TextFrame(label, data),
  'TT3': (label, data) => TextFrame(label, data),
  'TP1': (label, data) => TextFrame(label, data),
  'TP2': (label, data) => TextFrame(label, data),
  'TP3': (label, data) => TextFrame(label, data),
  'TP4': (label, data) => TextFrame(label, data),
  'TCM': (label, data) => TextFrame(label, data),
  'TXT': (label, data) => TextFrame(label, data),
  'TLA': (label, data) => TextFrame(label, data),
  'TCO': (label, data) => TextFrame(label, data),
  'TAL': (label, data) => TextFrame(label, data),
  'TPA': (label, data) => TextFrame(label, data),
  'TRK': (label, data) => TextFrame(label, data),
  'TRC': (label, data) => TextFrame(label, data),
  'TYE': (label, data) => TextFrame(label, data),
  'TDA': (label, data) => TextFrame(label, data),
  'TIM': (label, data) => TextFrame(label, data),
  'TRD': (label, data) => TextFrame(label, data),
  'TMT': (label, data) => TextFrame(label, data),
  'TFT': (label, data) => TextFrame(label, data),
  'TBP': (label, data) => TextFrame(label, data),
  'TCR': (label, data) => TextFrame(label, data),
  'TPB': (label, data) => TextFrame(label, data),
  'TEN': (label, data) => TextFrame(label, data),
  'TSS': (label, data) => TextFrame(label, data),
  'TOF': (label, data) => TextFrame(label, data),
  'TLE': (label, data) => TextFrame(label, data),
  'TSI': (label, data) => TextFrame(label, data),
  'TDY': (label, data) => TextFrame(label, data),
  'TKE': (label, data) => TextFrame(label, data),
  'TOT': (label, data) => TextFrame(label, data),
  'TOA': (label, data) => TextFrame(label, data),
  'TOL': (label, data) => TextFrame(label, data),
  'TOR': (label, data) => TextFrame(label, data),
  'TXX': (label, data) => UserDefinedFrame(label, data),
  'WXX': (label, data) => UserDefinedFrame(label, data),
  'WAF': (label, data) => UrlFrame(label, data),
  'WAR': (label, data) => UrlFrame(label, data),
  'WAS': (label, data) => UrlFrame(label, data),
  'WCM': (label, data) => UrlFrame(label, data),
  'WCP': (label, data) => UrlFrame(label, data),
  'WPB': (label, data) => UrlFrame(label, data),
  'MCI': (label, data) => BinaryFrame(label, data),
  'ETC': (label, data) => TimestampFrame(label, data),
  'STC': (label, data) => TimestampFrame(label, data),
  'ULT': (label, data) => LangDescTextFrame(label, data),
  'COM': (label, data) => LangDescTextFrame(label, data),
};


class ID3v2_2Parser {
  static ID3Tag parseForward(Uint8List data, {int start = 0}) {
    // Informal spec here: http://id3.org/id3v2-00
    // The "ID3" identifier
    if (!(
         data[start    ] == 0x49  // "I"
      && data[start + 1] == 0x44  // "D"
      && data[start + 2] == 0x33  // "3"
    ))
      throw BadTagException('Missing "ID3" identifier');

    // Version identifier
    if (!(
         data[start + 3] == 0x02
      && data[start + 4] == 0x00
    ))
      throw BadTagException('Expected v2.2.0 tag, v2.${data[start + 3]}.${data[start + 4]} found');

    // Flag bits
    if (!(
      data[start + 5] & 0x7F == 0  // 0x7F == 0b1111111
    ))
      throw BadTagException('Expected only bit 7 to be set for flags');

    bool unsync = data[start + 5] & 0x80 == 1;  // 0x80 == 0b10000000
    // Tag size
    int tagSize = readInt(data.getRange(start + 6, start + 10), synchSafe: true);

    // Frames
    int cursor = start + 10;
    var frames = Map<String, List<ID3Frame>>();
    while (cursor < start + 10 + tagSize) {
      var frameLabel = String.fromCharCodes(data.getRange(cursor, cursor + 3));
      if (frameLabel == '\x00\x00\x00') {
        break;  // Hit padding bytes
      }
      int frameSize = readInt(data.getRange(cursor + 3, cursor + 6));
      var frameData = Uint8List.view(data.buffer, cursor + 6, frameSize);
      var frame = frameByID[frameLabel](
        frameLabel,
        unsync ? removeUnsync(frameData) : frameData,
      );
      if (frames.containsKey(frameLabel)) {
        frames[frameLabel].add(frame);
      } else {
        frames[frameLabel] = [frame];
      }
      cursor += 6 + frameSize;
    }

    return ID3Tag(
      version: ID3.v2_2,
      frames: frames,
    );
  }
}
