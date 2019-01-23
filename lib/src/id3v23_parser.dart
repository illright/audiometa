import 'dart:typed_data';

import 'tag_types.dart';
import 'exceptions.dart';
import 'helpers.dart';
import 'id3v23_frames.dart';


const decompressedSizeBit = 0x80;
const encryptionMethodBit = 0x40;
const groupIDBit = 0x20;

final frameByID = <String, ID3Frame Function(String, V23FrameFlags, Uint8List)>{
  'UFID': (label, flags, data) => UFID.parse(label, flags, data),
  'TALB': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TBPM': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TCOM': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TCON': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TCOP': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TDAT': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TDLY': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TENC': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TEXT': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TFLT': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TIME': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TIT1': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TIT2': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TIT3': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TKEY': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TLAN': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TLEN': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TMED': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TOAL': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TOFN': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TOLY': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TOPE': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TORY': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TOWN': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TPE1': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TPE2': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TPE3': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TPE4': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TPOS': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TPUB': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TRCK': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TRDA': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TRSN': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TRSO': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TSIZ': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TSRC': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TSSE': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TYER': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TXXX': (label, flags, data) => UserDefinedFrame.parse(label, flags, data),
  'WXXX': (label, flags, data) => UserDefinedFrame.parse(label, flags, data),
  'WCOM': (label, flags, data) => UrlFrame.parse(label, flags, data),
  'WCOP': (label, flags, data) => UrlFrame.parse(label, flags, data),
  'WOAF': (label, flags, data) => UrlFrame.parse(label, flags, data),
  'WOAR': (label, flags, data) => UrlFrame.parse(label, flags, data),
  'WOAS': (label, flags, data) => UrlFrame.parse(label, flags, data),
  'WORS': (label, flags, data) => UrlFrame.parse(label, flags, data),
  'WPAY': (label, flags, data) => UrlFrame.parse(label, flags, data),
  'WPUB': (label, flags, data) => UrlFrame.parse(label, flags, data),
  'IPLS': (label, flags, data) => IPLS.parse(label, flags, data),
  'MCDI': (label, flags, data) => MCDI.parse(label, flags, data),
  'ETCO': (label, flags, data) => TimestampFrame.parse(label, flags, data),
  'SYTC': (label, flags, data) => TimestampFrame.parse(label, flags, data),
  'POSS': (label, flags, data) => TimestampFrame.parse(label, flags, data),
  'MLLT': (label, flags, data) => MLLT.parse(label, flags, data),
  'USLT': (label, flags, data) => LangDescTextFrame.parse(label, flags, data),
  'COMM': (label, flags, data) => LangDescTextFrame.parse(label, flags, data),
  'SYLT': (label, flags, data) => SYLT.parse(label, flags, data),
  'RVAD': (label, flags, data) => RVAD.parse(label, flags, data),
  'EQUA': (label, flags, data) => EQUA.parse(label, flags, data),
  'RVRB': (label, flags, data) => RVRB.parse(label, flags, data),
  'APIC': (label, flags, data) => APIC.parse(label, flags, data),
  'GEOB': (label, flags, data) => GEOB.parse(label, flags, data),
  'PCNT': (label, flags, data) => PCNT.parse(label, flags, data),
  'POPM': (label, flags, data) => POPM.parse(label, flags, data),
  'RBUF': (label, flags, data) => RBUF.parse(label, flags, data),
  'AENC': (label, flags, data) => AENC.parse(label, flags, data),
  'LINK': (label, flags, data) => LINK.parse(label, flags, data),
  'USER': (label, flags, data) => USER.parse(label, flags, data),
  'OWNE': (label, flags, data) => OWNE.parse(label, flags, data),
  'COMR': (label, flags, data) => COMR.parse(label, flags, data),
  'ENCR': (label, flags, data) => ENCR.parse(label, flags, data),
  'GRID': (label, flags, data) => GRID.parse(label, flags, data),
  'PRIV': (label, flags, data) => PRIV.parse(label, flags, data),
};

class ID3v23Parser {
  static ID3Tag parseForward(Uint8List data, {int start = 0}) {
    // Informal spec here: http://id3.org/id3v2.3.0
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
         parser.getByte() == 0x03
      && parser.getByte() == 0x00
    ))
      throw BadTagException('Expected v2.3.0 tag, v2.${data[start + 3]}.${data[start + 4]} found');

    // Flag bits
    int flags = parser.getByte();
    if (!(
      flags & 0x1F == 0  // 0x1F == 0b00011111
    ))
      throw BadTagException('Expected only bits 7, 6, 5 to be set for flags');

    bool unsync = flags & 0x80 != 0;  // 0x80 == 0b10000000
    bool extHeaderPresent = flags & 0x40 != 0;  // 0x40 == 0b01000000
    // Tag size
    int tagSize = parser.getInt(size: 4, synchSafe: true);

    if (unsync) {
      data = resync(data);
    }

    // Extended header
    V23ExtHeader extHeader;
    if (extHeaderPresent) {
      int extHeaderSize = parser.getInt(size: 4);
      extHeader = V23ExtHeader.parse(parser.getBytes(size: extHeaderSize + 4));
    }

    // Frames
    var frames = Map<String, List<ID3Frame>>();
    while (!parser.exceeds(parser.cursor + tagSize)) {
      var frameLabel = parser.getString(size: 4);
      if (frameLabel == '\x00\x00\x00\x00') {
        break;  // Hit padding bytes
      }
      int frameSize = parser.getInt(size: 4);
      int frameFlags = parser.getInt(size: 2);
      var flagStorage = V23FrameFlags();
      flagStorage.init(frameFlags);

      // Frame flag data
      if (frameFlags & 0x80 != 0) {  // 0x80 == 0b10000000
        flagStorage[decompressedSizeBit] = parser.getInt(size: 4);
      }

      if (frameFlags & 0x40 != 0) {  // 0x40 == 0b01000000
        flagStorage[encryptionMethodBit] = parser.getByte();
      }

      if (frameFlags & 0x20 != 0) {  // 0x20 == 0b00100000
        flagStorage[groupIDBit] = parser.getByte();
      }

      var frameData = parser.getBytes(size: frameSize);
      ID3Frame frame;
      if (frameByID.containsKey(frameLabel)) {
         frame = frameByID[frameLabel](frameLabel, flagStorage, frameData);
         if (frames.containsKey(frameLabel)) {
           frames[frameLabel].add(frame);
         } else {
           frames[frameLabel] = [frame];
         }
      } else {
        print('Frame $frameLabel not found.');
      }
    }

    return ID3Tag(
      version: ID3.v2_3,
      frames: frames,
      flags: flags,
      extHeader: extHeader,
    );
  }
}
