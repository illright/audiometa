import 'dart:typed_data';

import 'tag_types.dart';
import 'exceptions.dart';
import 'helpers.dart';

const iso_8859_1 = 1;


/// UFI: Unique file identifier.
class UFI extends ID3Frame {
  String owner;
  Uint8List identifier;

  UFI.parse(String label, Uint8List data) : super(label) {
    if (data[0] == 0) {
      throw BadTagDataException('First byte is null in UFI frame.');
    }
    int nullSeparator = data.indexOf(0);
    owner = String.fromCharCodes(data.getRange(0, nullSeparator));
    identifier = getViewRegion(data, start: nullSeparator + 1);
  }

  UFI({this.owner, this.identifier}) : super('UFI');
}


/// Frame that mainly contains text.
///
/// This is an interface so it does not refer to any actual frames.
abstract class PlainTextFrame {
  String text;
  int encoding;
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
  String text;
  int encoding;
  String description;

  factory UserDefinedFrame.parse(String label, Uint8List data) {
    int encodingByte = data[0];
    int nullSeparator = data.indexOf(0, 1);

    Uint8List rawDescription = getViewRegion(data, start: 1, end: nullSeparator);
    Uint8List rawText = getViewRegion(data, start: nullSeparator + 1);

    return UserDefinedFrame(
      label,
      description: decodeByEncodingByte(rawDescription, encodingByte),
      text: decodeByEncodingByte(rawText, encodingByte),
      encoding: encodingByte,
    );
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
    encoding = data[0];

    int cursor = 1;
    int closestZero, secondClosestZero;
    involvement = Map<String, String>();

    while (cursor < data.length) {
      closestZero = data.indexOf(0, cursor);
      secondClosestZero = data.indexOf(0, closestZero + 1);
      var key = decodeByEncodingByte(
        getViewRegion(data, start: cursor, end: closestZero),
        encoding
      );
      var value = decodeByEncodingByte(
        getViewRegion(data, start: closestZero + 1, end: secondClosestZero),
        encoding
      );
      involvement[key] = value;
      cursor = secondClosestZero + 1;
    }
  }

  IPL(this.involvement, {this.encoding = iso_8859_1}) : super('IPL');
}


/// Frame that mainly contains binary data, the parsing of which is out of scope of this library.
///
/// This is an interface so it does not refer to any actual frames.
class BinaryFrame {
  Uint8List data;
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
    framesBetweenRef = readInt(data.getRange(0, 2));
    bytesBetweenRef = readInt(data.getRange(2, 5));
    msBetweenRef = readInt(data.getRange(5, 8));
    bitsForByteDev = data[8];
    bitsForMsDev = data[9];
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
  String language;
  String description;
  String text;
  int encoding;

  factory LangDescTextFrame.parse(String label, Uint8List data) {
    int encodingByte = data[0];
    String language = String.fromCharCodes(data.getRange(1, 4));
    int nullSeparator = data.indexOf(0, 4);

    final rawDescription = getViewRegion(data, start: 4, end: nullSeparator);
    final rawText = getViewRegion(data, start: nullSeparator + 1);

    return LangDescTextFrame(
      label,
      language: language,
      description: decodeByEncodingByte(rawDescription, encodingByte),
      text: decodeByEncodingByte(rawText, encodingByte),
      encoding: encodingByte,
    );
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
    encoding = data[0];
    language = String.fromCharCodes(data.getRange(1, 4));
    timestampType = data[4];
    contentType = data[5];
    int nullSeparator = data.indexOf(0, 6);

    final rawDescriptor = getViewRegion(data, start: 6, end: nullSeparator);
    descriptor = decodeByEncodingByte(rawDescriptor, encoding);
    data = getViewRegion(data, start: nullSeparator + 1);
  }

  SLT({this.language, this.timestampType, this.contentType, this.descriptor,
      this.data, this.encoding = iso_8859_1}) : super('SLT');
}


/// RVA: Relative volume adjustment.
class RVA extends ID3Frame {
  int incrementFlags;
  int bitsForVolume;
  int relChangeLeft;
  int relChangeRight;
  int peakLeft;
  int peakRight;

  RVA.parse(String label, Uint8List data) : super('RVA') {
    incrementFlags = data[0];
    if (incrementFlags & 0xFC != 0) {
      throw BadTagDataException('Unknown flags set for increment/decrement.');
    }
    bitsForVolume = data[1];

    final volumeFieldSize = (bitsForVolume / 8).ceil() * 8;
    int offset = 2;
    relChangeLeft = readInt(data.getRange(offset, offset + volumeFieldSize));
    offset += volumeFieldSize;
    relChangeRight = readInt(data.getRange(offset, offset + volumeFieldSize));
    offset += volumeFieldSize;
    peakLeft = readInt(data.getRange(offset, offset + volumeFieldSize));
    offset += volumeFieldSize;
    peakRight = readInt(data.getRange(offset, offset + volumeFieldSize));
  }

  RVA({this.incrementFlags, this.bitsForVolume, this.relChangeLeft, this.relChangeRight,
      this.peakLeft, this.peakRight}) : super('RVA');
}


/// EQU: Equalisation
class EQU extends ID3Frame implements BinaryFrame {
  int adjustmentBits;
  Uint8List data;

  EQU.parse(String label, Uint8List data) : adjustmentBits = data[0],
      data = getViewRegion(data, start: 1), super(label);

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
        super(label);

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

  String imageFormat;
  int pictureType;
  String description;
  Uint8List data;

  factory PIC.parse(String label, Uint8List data) {
    int encodingByte = data[0];
    final imageFormat = String.fromCharCodes(data.getRange(1, 4));
    int pictureType = data[4];

    int nullSeparator = data.indexOf(0, 4);
    final rawDescription = getViewRegion(data, start: 4, end: nullSeparator);
    final imageData = getViewRegion(data, start: nullSeparator + 1);
    return PIC(
      imageFormat: imageFormat,
      pictureType: pictureType,
      description: decodeByEncodingByte(rawDescription, encodingByte),
      data: imageData
    );
  }

  PIC({this.imageFormat, this.pictureType, this.description, this.data}) : super('PIC');
}


/// GEO: General encapsulated object.
class GEO extends ID3Frame implements BinaryFrame {
  String mimeType;
  String filename;
  String description;
  Uint8List data;

  factory GEO.parse(String label, Uint8List data) {
    int encodingByte = data[0];
    int afterMimeType = data.indexOf(0, 1);
    int afterFilename = data.indexOf(0, afterMimeType + 1);
    int afterDescription = data.indexOf(0, afterFilename + 1);

    final rawMimeType = getViewRegion(data, start: 1, end: afterMimeType);
    final rawFilename = getViewRegion(data, start: afterMimeType + 1, end: afterFilename);
    final rawDescription = getViewRegion(data, start: afterFilename + 1, end: afterDescription);
    final rawData = getViewRegion(data, start: afterDescription + 1);

    return GEO(
      mimeType: decodeByEncodingByte(rawMimeType, encodingByte),
      filename: decodeByEncodingByte(rawFilename, encodingByte),
      description: decodeByEncodingByte(rawDescription, encodingByte),
      data: rawData,
    );
  }

  GEO({this.mimeType, this.filename, this.description, this.data}) : super('GEO');
}


/// CNT: Play counter.
class CNT extends ID3Frame {
  int playCount;

  CNT.parse(String label, Uint8List data) : playCount = readInt(data), super(label);

  CNT({this.playCount}) : super('CNT');
}


/// POP: Popularimeter.
class POP extends ID3Frame {
  String email;
  int rating;
  int playCount;

  POP.parse(String label, Uint8List data) : super('POP') {
    int nullSeparator = data.indexOf(0);
    email = String.fromCharCodes(data.getRange(0, nullSeparator));
    rating = data[nullSeparator + 1];

    if (nullSeparator + 2 != data.length) {
      playCount = readInt(data.getRange(nullSeparator + 2, data.length));
    } else {
      playCount = null;
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
    bufferSize = readInt(data.getRange(0, 3));
    if (data[3] & 0xFE != 0) {
      throw BadTagDataException('Unknown flags set in the embedded info byte.');
    }
    embeddedInfo = data[3] == 1;

    if (data.length != 4) {
      offsetToNextTag = readInt(data.getRange(4, data.length));
    } else {
      offsetToNextTag = null;
    }
  }

  BUF({this.bufferSize, this.embeddedInfo, this.offsetToNextTag}) : super('BUF');
}


/// CRM: Encrypted meta frame.
class CRM extends ID3Frame implements BinaryFrame {
  String owner;
  String explanation;
  Uint8List data;

  factory CRM.parse(String label, Uint8List data) {
    if (data[0] == 0) {
      throw BadTagDataException('First byte is null in CRM frame.');
    }
    int afterOwner = data.indexOf(0);
    int afterExplanation = data.indexOf(0, afterOwner + 1);

    final owner = String.fromCharCodes(data.getRange(0, afterOwner));
    final explanation = String.fromCharCodes(data.getRange(afterOwner + 1, afterExplanation));
    final encryptedData = Uint8List.view(data.buffer, afterExplanation + 1);

    return CRM(
      owner: owner,
      explanation: explanation,
      data: encryptedData
    );
  }

  CRM({this.owner, this.explanation, this.data}) : super('CRM');
}


/// CRA: Audio encryption.
class CRA extends ID3Frame implements BinaryFrame {
  String owner;
  int previewStart;
  int previewLength;
  Uint8List data;

  CRA.parse(String label, Uint8List data) : super('CRA') {
    if (data[0] == 0) {
      throw BadTagDataException('First byte is null in CRA frame.');
    }
    int afterOwner = data.indexOf(0);
    previewStart = readInt(data.getRange(afterOwner + 1, afterOwner + 3));
    previewLength = readInt(data.getRange(afterOwner + 3, afterOwner + 5));

    owner = String.fromCharCodes(data.getRange(0, afterOwner));
    data = getViewRegion(data, start: afterOwner + 5);
  }

  CRA({this.owner, this.previewStart, this.previewLength, this.data}) : super('CRA');
}


/// LNK: Linked information.
class LNK extends ID3Frame {
  String linkedFrame;
  String url;
  String idData;

  LNK.parse(String label, Uint8List data) : super('LNK') {
    linkedFrame = String.fromCharCodes(data.getRange(0, 3));
    int afterUrl = data.indexOf(0, 3);
    url = String.fromCharCodes(data.getRange(3, afterUrl));
    idData = String.fromCharCodes(data.getRange(afterUrl + 1, data.length));
  }

  LNK({this.linkedFrame, this.url, this.idData}) : super('LNK');
}
