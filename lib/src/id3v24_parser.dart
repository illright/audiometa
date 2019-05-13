import 'dart:typed_data';

import 'tag_types.dart';
import 'exceptions.dart';
import 'helpers.dart';
import 'id3v24_frames.dart';


final frameByID = <String, ID3Frame Function(String, V24FrameFlags, Uint8List)>{
  'UFID': (label, flags, data) => UFID.parse(label, flags, data),
  'TIT1': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TIT2': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TIT3': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TALB': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TOAL': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TRCK': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TPOS': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TSST': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TSRC': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TPE1': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TPE2': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TPE3': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TPE4': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TOPE': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TEXT': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TOLY': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TCOM': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TMCL': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TIPL': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TENC': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TBPM': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TLEN': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TKEY': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TLAN': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TCON': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TFLT': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TMED': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TCOP': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TPRO': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TPUB': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TOWN': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TRSN': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TRSO': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TOFN': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TDLY': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TDEN': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TDOR': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TDRC': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TDRL': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TDTG': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TSSE': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TSOA': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TSOP': (label, flags, data) => TextFrame.parse(label, flags, data),
  'TSOT': (label, flags, data) => TextFrame.parse(label, flags, data),
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
  'MCDI': (label, flags, data) => MCDI.parse(label, flags, data),
  'ETCO': (label, flags, data) => TimestampFrame.parse(label, flags, data),
  'SYTC': (label, flags, data) => TimestampFrame.parse(label, flags, data),
  'POSS': (label, flags, data) => TimestampFrame.parse(label, flags, data),
  'MLLT': (label, flags, data) => MLLT.parse(label, flags, data),
  'USLT': (label, flags, data) => LangDescTextFrame.parse(label, flags, data),
  'COMM': (label, flags, data) => LangDescTextFrame.parse(label, flags, data),
  'SYLT': (label, flags, data) => SYLT.parse(label, flags, data),
  'RVA2': (label, flags, data) => RVA2.parse(label, flags, data),
  'EQU2': (label, flags, data) => EQU2.parse(label, flags, data),
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
    // Informal spec here: http://id3.org/id3v2.4.0-structure
    var parser = BinaryParser(data, cursor: start);
    // The "ID3" identifier
    if (!(
         parser.getByte() == 0x49  // "I"
      && parser.getByte() == 0x44  // "D"
      && parser.getByte() == 0x33  // "3"
    ))
      throw BadTagException('Missing "ID3" identifier');

    // Version identifier
    var major = parser.getByte();
    var revision = parser.getByte();
    if (!(
         major == 0x04
      && revision == 0x00
    ))
      throw BadTagException('Expected v2.4.0 tag, v2.$major.$revision found');

    // Flag bits
    int tagFlags = parser.getByte();
    if (!(
      tagFlags & 0xF == 0  // 0xF == 0b00001111
    ))
      throw BadTagException('Expected only bits 7, 6, 5, 4 to be set for flags');

    bool unsync = tagFlags & 0x80 != 0;  // 0x80 == 0b10000000
    bool extHeaderPresent = tagFlags & 0x40 != 0;  // 0x40 == 0b01000000
    // Tag size
    int tagSize = parser.getInt(size: 4, synchSafe: true);

    if (unsync) {
      // It's safe to remove unsynchronization from the whole tag as the header has no 0xFF.
      data = resync(data);
      parser.update(data);
    }

    int tagEnd = parser.cursor + tagSize;

    // Extended header
    V24ExtHeader extHeader;
    if (extHeaderPresent) {
      int extHeaderSize = parser.getInt(size: 4, synchSafe: true);
      extHeader = V24ExtHeader.parse(parser.getBytes(size: extHeaderSize));
    }

    // Frames
    var frames = Map<String, List<ID3Frame>>();
    while (!parser.exceeds(tagEnd)) {
      var frameLabel = parser.getString(size: 4);
      if (frameLabel == '\x00\x00\x00\x00') {
        break;  // Hit padding bytes
      }
      int frameSize = parser.getInt(size: 4, synchSafe: true);
      int frameFlagsInt = parser.getInt(size: 2);
      var frameFlags = V24FrameFlags.init(frameFlagsInt);

      // Frame flag data
      if (frameFlagsInt & V24FrameFlags.groupIDBit != 0) {
        frameFlags[V24FrameFlags.groupIDBit] = parser.getByte();
      }

      if (frameFlagsInt & V24FrameFlags.encryptionMethodBit != 0) {
        frameFlags[V24FrameFlags.encryptionMethodBit] = parser.getByte();
      }

      if (frameFlagsInt & V24FrameFlags.dataLengthIndcatorBit != 0) {
        frameFlags[V24FrameFlags.dataLengthIndcatorBit] = parser.getInt(size: 4, synchSafe: true);
      }

      var frameData = parser.getBytes(size: frameSize);
      if (!unsync && frameFlags.contain(V24FrameFlags.unsyncBit)) {
        frameData = resync(frameData);
      }

      ID3Frame frame;
      if (frameByID.containsKey(frameLabel)) {
         frame = frameByID[frameLabel](frameLabel, frameFlags, frameData);
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
      version: ID3.v2_4,
      frames: frames,
      flags: tagFlags,
      extHeader: extHeader,
    );
  }
}
