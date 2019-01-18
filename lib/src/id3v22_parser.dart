import 'dart:typed_data';

import 'tag_types.dart';
import 'exceptions.dart';
import 'helpers.dart';
import 'id3v22_frames.dart';


final frameByID = <String, ID3Frame Function(String, Uint8List)>{
  'UFI': (label, data) => UFI.parse(label, data),
  'IPL': (label, data) => IPL.parse(label, data),
  'MLL': (label, data) => MLL.parse(label, data),
  'SLT': (label, data) => SLT.parse(label, data),
  'RVA': (label, data) => RVA.parse(label, data),
  'EQU': (label, data) => EQU.parse(label, data),
  'REV': (label, data) => REV.parse(label, data),
  'PIC': (label, data) => PIC.parse(label, data),
  'GEO': (label, data) => GEO.parse(label, data),
  'CNT': (label, data) => CNT.parse(label, data),
  'POP': (label, data) => POP.parse(label, data),
  'BUF': (label, data) => BUF.parse(label, data),
  'CRM': (label, data) => CRM.parse(label, data),
  'CRA': (label, data) => CRA.parse(label, data),
  'LNK': (label, data) => LNK.parse(label, data),
  'TT1': (label, data) => TextFrame.parse(label, data),
  'TT2': (label, data) => TextFrame.parse(label, data),
  'TT3': (label, data) => TextFrame.parse(label, data),
  'TP1': (label, data) => TextFrame.parse(label, data),
  'TP2': (label, data) => TextFrame.parse(label, data),
  'TP3': (label, data) => TextFrame.parse(label, data),
  'TP4': (label, data) => TextFrame.parse(label, data),
  'TCM': (label, data) => TextFrame.parse(label, data),
  'TXT': (label, data) => TextFrame.parse(label, data),
  'TLA': (label, data) => TextFrame.parse(label, data),
  'TCO': (label, data) => TextFrame.parse(label, data),
  'TAL': (label, data) => TextFrame.parse(label, data),
  'TPA': (label, data) => TextFrame.parse(label, data),
  'TRK': (label, data) => TextFrame.parse(label, data),
  'TRC': (label, data) => TextFrame.parse(label, data),
  'TYE': (label, data) => TextFrame.parse(label, data),
  'TDA': (label, data) => TextFrame.parse(label, data),
  'TIM': (label, data) => TextFrame.parse(label, data),
  'TRD': (label, data) => TextFrame.parse(label, data),
  'TMT': (label, data) => TextFrame.parse(label, data),
  'TFT': (label, data) => TextFrame.parse(label, data),
  'TBP': (label, data) => TextFrame.parse(label, data),
  'TCR': (label, data) => TextFrame.parse(label, data),
  'TPB': (label, data) => TextFrame.parse(label, data),
  'TEN': (label, data) => TextFrame.parse(label, data),
  'TSS': (label, data) => TextFrame.parse(label, data),
  'TOF': (label, data) => TextFrame.parse(label, data),
  'TLE': (label, data) => TextFrame.parse(label, data),
  'TSI': (label, data) => TextFrame.parse(label, data),
  'TDY': (label, data) => TextFrame.parse(label, data),
  'TKE': (label, data) => TextFrame.parse(label, data),
  'TOT': (label, data) => TextFrame.parse(label, data),
  'TOA': (label, data) => TextFrame.parse(label, data),
  'TOL': (label, data) => TextFrame.parse(label, data),
  'TOR': (label, data) => TextFrame.parse(label, data),
  'TXX': (label, data) => UserDefinedFrame.parse(label, data),
  'WXX': (label, data) => UserDefinedFrame.parse(label, data),
  'WAF': (label, data) => UrlFrame.parse(label, data),
  'WAR': (label, data) => UrlFrame.parse(label, data),
  'WAS': (label, data) => UrlFrame.parse(label, data),
  'WCM': (label, data) => UrlFrame.parse(label, data),
  'WCP': (label, data) => UrlFrame.parse(label, data),
  'WPB': (label, data) => UrlFrame.parse(label, data),
  'MCI': (label, data) => MCI.parse(label, data),
  'ETC': (label, data) => TimestampFrame.parse(label, data),
  'STC': (label, data) => TimestampFrame.parse(label, data),
  'ULT': (label, data) => LangDescTextFrame.parse(label, data),
  'COM': (label, data) => LangDescTextFrame.parse(label, data),
};


class ID3v22Parser {
  static ID3Tag parseForward(Uint8List data, {int start = 0}) {
    // Informal spec here: http://id3.org/id3v2-00
    var parser = BinaryParser(data, cursor: start);
    // The "ID3" identifier
    if (!(
         parser.getByte() == 0x49  // "I"
      && parser.getByte() == 0x44  // "D"
      && parser.getByte() == 0x33  // "3"
    ))
      throw BadTagException('Missing "ID3" identifier');

    // Version identifier
    if (!(
         parser.getByte() == 0x02
      && parser.getByte() == 0x00
    ))
      throw BadTagException('Expected v2.2.0 tag, v2.${data[start + 3]}.${data[start + 4]} found');

    // Flag bits
    int flags = parser.getByte();
    if (!(
      flags & 0x7F == 0  // 0x7F == 0b01111111
    ))
      throw BadTagException('Expected only bit 7 to be set for flags');

    bool unsync = flags & 0x80 != 0;  // 0x80 == 0b10000000
    // Tag size
    int tagSize = parser.getInt(4, synchSafe: true);

    // Frames
    var frames = Map<String, List<ID3Frame>>();
    if (unsync) {
      // It's safe to remove unsynchronization from the whole tag as the header has no 0xFF.
      data = resync(data);
    }
    while (!parser.exceeds(tagSize)) {
      var frameLabel = parser.getString(3);
      if (frameLabel == '\x00\x00\x00') {
        break;  // Hit padding bytes
      }
      int frameSize = parser.getInt(3);
      var frameData = parser.getBytes(frameSize);
      var frame = frameByID[frameLabel](frameLabel, frameData);

      if (frames.containsKey(frameLabel)) {
        frames[frameLabel].add(frame);
      } else {
        frames[frameLabel] = [frame];
      }
    }

    return ID3Tag(
      version: ID3.v2_2,
      flags: flags,
      frames: frames,
    );
  }
}
