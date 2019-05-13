import 'dart:typed_data';

import 'tag_types.dart';
import 'exceptions.dart';
import 'helpers.dart';

const iso_8859_1 = 0;


/// UFI: Unique file identifier.
class UFI extends ID3Frame {
  String owner;
  Uint8List identifier;

  UFI.parse(String label, Uint8List data) : super(label) {
    var parser = BinaryParser(data);
    if (parser.nextByte() == 0) {
      throw BadTagDataException('Owner identifier cannot be empty.');
    }
    owner = parser.getStringUntilNull();
    identifier = parser.getBytesUntilEnd();
  }

  UFI({this.owner, this.identifier}) : super('UFI');
}


/// T00-TZZ, excluding TXX: Text information frames.
///
/// Refers to the following frames:
/// - TT1: Content group description
/// - TT2: Title/Songname/Content description
/// - TT3: Subtitle/Description refinement
/// - TP1: Lead artist(s)/Lead performer(s)/Soloist(s)/Performing group
/// - TP2: Band/Orchestra/Accompaniment
/// - TP3: Conductor
/// - TP4: Interpreted, remixed, or otherwise modified by
/// - TCM: Composer(s)
/// - TXT: Lyricist(s)/text writer(s)
/// - TLA: Language(s)
/// - TCO: Content type
/// - TAL: Album/Movie/Show title
/// - TPA: Part of a set
/// - TRK: Track number/Position in set
/// - TRC: ISRC
/// - TYE: Year
/// - TDA: Date
/// - TIM: Time
/// - TRD: Recording dates
/// - TMT: Media type
/// - TFT: File type
/// - TBP: BPM
/// - TCR: Copyright message
/// - TPB: Publisher
/// - TEN: Encoded by
/// - TSS: Software/hardware and settings used for encoding
/// - TOF: Original filename
/// - TLE: Length
/// - TSI: Size
/// - TDY: Playlist delay
/// - TKE: Initial key
/// - TOT: Original album/Movie/Show title
/// - TOA: Original artist(s)/performer(s)
/// - TOL: Original Lyricist(s)/text writer(s)
/// - TOR: Original release year
class TextFrame extends ID3Frame implements PlainTextFrame {
  String text;
  int encoding;

  TextFrame.parse(String label, Uint8List data)
      : text = decodeByEncodingByte(getViewRegion(data, start: 1), data[0]), encoding = data[0],
        super(label);

  TextFrame(String label, {this.text, this.encoding = iso_8859_1}) : super(label);
}


/// User defined frames.
///
/// Refers to the following frames:
/// - TXX: User defined text information frame
/// - WXX: User defined URL link frame
class UserDefinedFrame extends ID3Frame implements PlainTextFrame {
  int encoding;
  String description;
  String text;

  UserDefinedFrame.parse(String label, Uint8List data) : super(label) {
    var parser = BinaryParser(data);
    encoding = parser.getByte();
    description = parser.getStringUntilNull(encoding: encoding);
    text = parser.getStringUntilEnd(encoding: encoding);
  }

  UserDefinedFrame(String label, {this.description, this.text, this.encoding = iso_8859_1})
      : super(label);
}


/// W00-WZZ, excluding WXX: URL link frames.
///
/// Refers to the following frames:
/// - WAF: Official audio file webpage
/// - WAR: Official artist/performer webpage
/// - WAS: Official audio source webpage
/// - WCM: Commercial information
/// - WCP: Copyright/Legal information
/// - WPB: Publishers official webpage
class UrlFrame extends ID3Frame implements PlainTextFrame {
  String text;
  int encoding;

  UrlFrame.parse(String label, Uint8List data)
      : text = String.fromCharCodes(data), encoding = iso_8859_1, super(label);

  UrlFrame(String label, {this.text}) : encoding = iso_8859_1, super(label);
}


/// IPL: Involved people list.
class IPL extends ID3Frame {
  Map<String, String> involvement;
  int encoding;

  IPL.parse(String label, Uint8List data) : super('IPL') {
    var parser = BinaryParser(data);
    encoding = parser.getByte();

    involvement = Map<String, String>();

    while (parser.hasMoreData()) {
      var key = parser.getStringUntilNull(encoding: encoding);
      var value = parser.getStringUntilNull(encoding: encoding);
      involvement[key] = value;
    }
  }

  IPL(this.involvement, {this.encoding = iso_8859_1}) : super('IPL');
}


/// MCI: Music CD Identifier
class MCI extends ID3Frame implements BinaryFrame {
  Uint8List data;

  MCI.parse(String label, Uint8List data) : data = data, super('MCI');

  MCI({this.data}) : super('MCI');
}


/// Frame that includes a timestamp of a certain type.
///
/// Refers to the following frames:
/// - ETC: Event timing codes
/// - STC: Synced tempo codes
class TimestampFrame extends ID3Frame implements BinaryFrame {
  int timestampType;
  Uint8List data;

  TimestampFrame.parse(String label, Uint8List data)
      : timestampType = data[0], data = getViewRegion(data, start: 1), super(label);

  TimestampFrame(String label, {this.timestampType, this.data}) : super(label);
}


/// MLL: MPEG location lookup table.
class MLL extends ID3Frame implements BinaryFrame {
  int framesBetweenRef;
  int bytesBetweenRef;
  int msBetweenRef;
  int bitsForByteDev;
  int bitsForMsDev;
  Uint8List data;

  MLL.parse(String label, Uint8List data) : data = getViewRegion(data, start: 10), super('MLL') {
    var parser = BinaryParser(data);
    framesBetweenRef = parser.getInt(size: 2);
    bytesBetweenRef = parser.getInt(size: 3);
    msBetweenRef = parser.getInt(size: 3);
    bitsForByteDev = parser.getByte();
    bitsForMsDev = parser.getByte();
  }

  MLL({this.framesBetweenRef, this.bytesBetweenRef, this.msBetweenRef,
      this.bitsForByteDev, this.bitsForMsDev, this.data}) : super('MLL');
}


/// A text frame that contains information about the language and a content description.
///
/// Refers to the following frames:
/// - ULT: Unsynchronised lyrics/text transcription
/// - COM: Comments
class LangDescTextFrame extends ID3Frame implements PlainTextFrame {
  int encoding;
  String language;
  String description;
  String text;

  LangDescTextFrame.parse(String label, Uint8List data) : super(label) {
    var parser = BinaryParser(data);

    encoding = parser.getByte();
    language = parser.getString(size: 3);
    description = parser.getStringUntilNull(encoding: encoding);
    text = parser.getStringUntilEnd(encoding: encoding);
  }

  LangDescTextFrame(String label,
      {this.language, this.description, this.text, this.encoding = iso_8859_1}) : super(label);
}


/// SLT: Synchronised lyrics/text.
class SLT extends ID3Frame implements BinaryFrame {
  int encoding;
  String language;
  int timestampType;
  int contentType;
  String descriptor;
  Uint8List data;

  SLT.parse(String label, Uint8List data) : super('SLT') {
    var parser = BinaryParser(data);
    encoding = parser.getByte();
    language = parser.getString(size: 3);
    timestampType = parser.getByte();
    contentType = parser.getByte();
    descriptor = parser.getStringUntilNull(encoding: encoding);
    data = parser.getBytesUntilEnd();
  }

  SLT({this.language, this.timestampType, this.contentType, this.descriptor,
      this.data, this.encoding = iso_8859_1}) : super('SLT');
}


/// RVA: Relative volume adjustment.
class RVA extends ID3Frame {
  int incrementFlags;
  int bitsForVolume;
  int relChangeRight;
  int relChangeLeft;
  int peakRight;
  int peakLeft;

  RVA.parse(String label, Uint8List data) : super('RVA') {
    var parser = BinaryParser(data);
    incrementFlags = parser.getByte();
    if (incrementFlags & 0xFC != 0) {  // 0xFC == 0b11111100
      throw BadTagDataException('Unknown flags set for increment/decrement.');
    }
    bitsForVolume = parser.getByte();

    final volumeFieldSize = (bitsForVolume / 8).ceil() * 8;
    if (volumeFieldSize == 0) {
      throw BadTagDataException('Bits used for volume description cannot be zero.');
    }
    relChangeRight = parser.getInt(size: volumeFieldSize);
    relChangeLeft = parser.getInt(size: volumeFieldSize);

    if (parser.hasMoreData()) {
      peakRight = parser.getInt(size: volumeFieldSize);
      peakLeft = parser.getInt(size: volumeFieldSize);
    }
  }

  RVA({this.incrementFlags, this.bitsForVolume, this.relChangeRight, this.relChangeLeft,
      this.peakRight, this.peakLeft}) : super('RVA');
}


/// EQU: Equalisation
class EQU extends ID3Frame implements BinaryFrame {
  int adjustmentBits;
  Uint8List data;

  EQU.parse(String label, Uint8List data) : adjustmentBits = data[0],
      data = getViewRegion(data, start: 1), super('EQU');

  EQU({this.adjustmentBits, this.data}) : super('EQU');
}


/// REV: Reverb
class REV extends ID3Frame {
  int reverbLeft;
  int reverbRight;
  int bounceLeft;
  int bounceRight;
  int feedbackLL;
  int feedbackLR;
  int feedbackRR;
  int feedbackRL;
  int premixLR;
  int premixRL;

  REV.parse(String label, Uint8List data)
      : reverbLeft = readInt(data.getRange(0, 2)),
        reverbRight = readInt(data.getRange(2, 4)),
        bounceLeft = data[4], bounceRight = data[5],
        feedbackLL = data[6], feedbackLR = data[7],
        feedbackRR = data[8], feedbackRL = data[9],
        premixLR = data[10], premixRL = data[11],
        super('REV');

  REV({
    this.reverbLeft,
    this.reverbRight,
    this.bounceLeft,
    this.bounceRight,
    this.feedbackLL,
    this.feedbackLR,
    this.feedbackRR,
    this.feedbackRL,
    this.premixLR,
    this.premixRL,
  }) : super('REV');
}


/// PIC: Attached picture.
class PIC extends ID3Frame implements BinaryFrame {
  static const other = 1;
  static const fileIcon = 2;
  static const otherFileIcon = 3;
  static const frontCover = 4;
  static const backCover = 5;
  static const leaflet = 6;
  static const media = 7;
  static const leadArtist = 8;
  static const artist = 9;
  static const conductor = 10;
  static const band = 11;
  static const composer = 12;
  static const lyricist = 13;
  static const recordingLocation = 14;
  static const duringRecording = 15;
  static const duringPerformance = 16;
  static const movieScreenCapture = 17;
  static const fish = 18;
  static const illustration = 19;
  static const bandLogo = 20;
  static const publisherLogo = 21;

  int encoding;
  String imageFormat;
  int pictureType;
  String description;
  Uint8List data;

  PIC.parse(String label, Uint8List data) : super('PIC') {
    var parser = BinaryParser(data);
    encoding = parser.getByte();

    imageFormat = parser.getString(size: 3);
    pictureType = parser.getByte();
    description = parser.getStringUntilNull(encoding: encoding);
    this.data = parser.getBytesUntilEnd();
  }

  PIC({this.imageFormat, this.pictureType, this.description, this.data}) : super('PIC');
}


/// GEO: General encapsulated object.
class GEO extends ID3Frame implements BinaryFrame {
  int encoding;
  String mimeType;
  String filename;
  String description;
  Uint8List data;

  GEO.parse(String label, Uint8List data) : super('GEO') {
    var parser = BinaryParser(data);
    encoding = parser.getByte();
    mimeType = parser.getStringUntilNull(encoding: encoding);
    filename = parser.getStringUntilNull(encoding: encoding);
    description = parser.getStringUntilNull(encoding: encoding);
    data = parser.getBytesUntilEnd();
  }

  GEO({this.mimeType, this.filename, this.description, this.data}) : super('GEO');
}


/// CNT: Play counter.
class CNT extends ID3Frame {
  int playCount;

  CNT.parse(String label, Uint8List data) : playCount = readInt(data), super('CNT');

  CNT({this.playCount}) : super('CNT');
}


/// POP: Popularimeter.
class POP extends ID3Frame {
  String email;
  int rating;
  int playCount;

  POP.parse(String label, Uint8List data) : super('POP') {
    var parser = BinaryParser(data);

    email = parser.getStringUntilNull();
    rating = parser.getByte();

    if (parser.hasMoreData()) {
      playCount = parser.getIntUntilEnd();
    }
  }

  POP({this.email, this.rating, this.playCount}) : super('POP');
}


/// BUF: Recommended buffer size.
class BUF extends ID3Frame {
  int bufferSize;
  bool embeddedInfo;
  int offsetToNextTag;

  BUF.parse(String label, Uint8List data) : super('BUF') {
    var parser = BinaryParser(data);
    bufferSize = parser.getInt(size: 3);
    if (parser.nextByte() & 0xFE != 0) {  // 0xFE == 0b11111110
      throw BadTagDataException('Unknown flags set in the embedded info byte.');
    }
    embeddedInfo = parser.getByte() == 0x1;

    if (parser.hasMoreData()) {
      offsetToNextTag = parser.getIntUntilEnd();
    }
  }

  BUF({this.bufferSize, this.embeddedInfo, this.offsetToNextTag}) : super('BUF');
}


/// CRM: Encrypted meta frame.
class CRM extends ID3Frame implements BinaryFrame {
  String owner;
  String description;
  Uint8List data;

  CRM.parse(String label, Uint8List data) : super('CRM') {
    var parser = BinaryParser(data);
    if (parser.nextByte() == 0) {
      throw BadTagDataException('Owner identifier cannot be empty');
    }

    owner = parser.getStringUntilNull();
    description = parser.getStringUntilNull();
    data = parser.getBytesUntilEnd();
  }

  CRM({this.owner, this.description, this.data}) : super('CRM');
}


/// CRA: Audio encryption.
class CRA extends ID3Frame implements BinaryFrame {
  String owner;
  int previewStart;
  int previewLength;
  Uint8List data;

  CRA.parse(String label, Uint8List data) : super('CRA') {
    var parser = BinaryParser(data);
    if (parser.nextByte() == 0) {
      throw BadTagDataException('Owner identifier cannot be empty.');
    }

    owner = parser.getStringUntilNull();
    previewStart = parser.getInt(size: 2);
    previewLength = parser.getInt(size: 2);
    data = parser.getBytesUntilEnd();
  }

  CRA({this.owner, this.previewStart, this.previewLength, this.data}) : super('CRA');
}


/// LNK: Linked information.
class LNK extends ID3Frame {
  String linkedFrame;
  String url;
  List<String> idData;

  LNK.parse(String label, Uint8List data) : super('LNK') {
    var parser = BinaryParser(data);
    linkedFrame = parser.getString(size: 3);
    url = parser.getStringUntilNull();
    idData = parser.getStringsUntilEnd();
  }

  LNK({this.linkedFrame, this.url, this.idData}) : super('LNK');
}
