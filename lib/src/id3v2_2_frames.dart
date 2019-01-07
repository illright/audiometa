import 'dart:typed_data';

import 'tag_types.dart';
import 'exceptions.dart';
import 'helpers.dart';


/// UFI: Unique file identifier.
class UFI extends ID3Frame {
  String owner;
  String identifier;

  UFI(String label, Uint8List data) : super(label, data) {
    if (data[0] == 0) {
      throw BadTagDataException('First byte is null in UFI frame.');
    }
    int nullSeparator = data.indexOf(0);
    owner = String.fromCharCodes(data.getRange(0, nullSeparator));
    identifier = String.fromCharCodes(data.getRange(nullSeparator + 1, data.length));
  }
}


/// Frame that mainly contains text.
///
/// This class is abstract so it does not refer to any actual frames.
abstract class PlainTextFrame extends ID3Frame {
  String text;

  PlainTextFrame(this.text, String label, Uint8List data) : super(label, data);
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
class TextFrame extends PlainTextFrame {
  TextFrame(String label, Uint8List data)
      : super(
          decodeByEncodingByte(getViewRegion(data, start: 1), data[0]),
          label,
          data
        );
}


/// User defined frames.
///
/// Refers to the following frames:
/// - TXX: User defined text information frame
/// - WXX: User defined URL link frame
class UserDefinedFrame extends PlainTextFrame {
  String description;

  factory UserDefinedFrame(String label, Uint8List data) {
    int encodingByte = data[0];
    int nullSeparator = data.indexOf(0, 1);

    Uint8List rawDescription = getViewRegion(data, start: 1, end: nullSeparator);
    Uint8List rawText = getViewRegion(data, start: nullSeparator + 1);

    return UserDefinedFrame._(
      decodeByEncodingByte(rawDescription, encodingByte),
      decodeByEncodingByte(rawText, encodingByte),
      label,
      data
    );
  }

  UserDefinedFrame._(this.description, String text, String label, Uint8List data)
      : super(text, label, data);
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
class UrlFrame extends PlainTextFrame {
  UrlFrame(String label, Uint8List data) : super(String.fromCharCodes(data), label, data);
}


/// IPL: Involved people list.
class IPL extends ID3Frame {
  Map<String, String> involvement;
  factory IPL(String label, Uint8List data) {
    Map<String, String> involvement;
    int encodingByte = data[0];

    int cursor = 1;
    int closestZero, secondClosestZero;
    while (cursor < data.length) {
      closestZero = data.indexOf(0, cursor);
      secondClosestZero = data.indexOf(0, closestZero + 1);
      var key = decodeByEncodingByte(
        getViewRegion(data, start: cursor, end: closestZero),
        encodingByte
      );
      var value = decodeByEncodingByte(
        getViewRegion(data, start: closestZero + 1, end: secondClosestZero),
        encodingByte
      );
      involvement[key] = value;
      cursor = secondClosestZero + 1;
    }
    return IPL._(involvement, label, data);
  }

  IPL._(this.involvement, String label, Uint8List data) : super(label, data);
}


/// Frame that doesn't have a special content-parsing algorithm.
///
/// Refers to the following frames:
/// - MCI: Music CD Identifier
class BinaryFrame extends ID3Frame {
  BinaryFrame(String label, Uint8List data) : super(label, data);
}


/// Frame that includes a timestamp of a certain type.
///
/// Refers to the following frames:
/// - ETC: Event timing codes
/// - STC: Synced tempo codes
class TimestampFrame extends ID3Frame {
  int timestampType;
  Uint8List binContent;

  TimestampFrame(String label, Uint8List data)
      : timestampType = data[0], binContent = getViewRegion(data, start: 1), super(label, data);
}


/// MLL: MPEG location lookup table.
class MLL extends ID3Frame {
  int framesBetweenRef;
  int bytesBetweenRef;
  int msBetweenRef;
  int bitsForByteDev;
  int bitsForMsDev;
  Uint8List referencesRaw;

  factory MLL(String label, Uint8List data) {
    final framesBetweenRef = readInt(data.getRange(0, 2));
    final bytesBetweenRef = readInt(data.getRange(2, 5));
    final msBetweenRef = readInt(data.getRange(5, 8));
    final bitsForByteDev = data[8];
    final bitsForMsDev = data[9];
    return MLL._(
      framesBetweenRef,
      bytesBetweenRef,
      msBetweenRef,
      bitsForByteDev,
      bitsForMsDev,
      getViewRegion(data, start: 10),
      label,
      data,
    );
  }

  MLL._(this.framesBetweenRef, this.bytesBetweenRef, this.msBetweenRef, this.bitsForByteDev,
      this.bitsForMsDev, this.referencesRaw, String label, Uint8List data) : super(label, data);
}


/// A text frame that contains information about the language and a content description.
///
/// Refers to the following frames:
/// - ULT: Unsynchronised lyrics/text transcription
/// - COM: Comments
class LangDescTextFrame extends PlainTextFrame {
  String language;
  String description;

  factory LangDescTextFrame(String label, Uint8List data) {
    int encodingByte = data[0];
    String language = String.fromCharCodes(data.getRange(1, 4));
    int nullSeparator = data.indexOf(0, 4);

    final rawDescription = getViewRegion(data, start: 4, end: nullSeparator);
    final rawText = getViewRegion(data, start: nullSeparator + 1);

    return LangDescTextFrame._(
      language,
      decodeByEncodingByte(rawDescription, encodingByte),
      decodeByEncodingByte(rawText, encodingByte),
      label,
      data
    );
  }

  LangDescTextFrame._(this.language, this.description, String text, String label, Uint8List data)
      : super(text, label, data);
}


/// SLT: Synchronised lyrics/text.
class SLT extends ID3Frame {
  int encodingByte;
  String language;
  int timestampType;
  int contentType;
  String descriptor;
  Uint8List rawLyrics;

  factory SLT(String label, Uint8List data) {
    int encodingByte = data[0];
    String language = String.fromCharCodes(data.getRange(1, 4));
    int timestampType = data[4];
    int contentType = data[5];
    int nullSeparator = data.indexOf(0, 6);

    final rawDescriptor = getViewRegion(data, start: 6, end: nullSeparator);
    final rawLyrics = getViewRegion(data, start: nullSeparator + 1);

    return SLT._(
      encodingByte,
      language,
      timestampType,
      contentType,
      decodeByEncodingByte(rawDescriptor, encodingByte),
      rawLyrics,
      label,
      data
    );
  }

  SLT._(this.encodingByte, this.language, this.timestampType, this.contentType, this.descriptor,
      this.rawLyrics, String label, Uint8List data) : super(label, data);
}


/// RVA: Relative volume adjustment.
class RVA extends ID3Frame {
  int incrementFlags;
  int bitsForVolume;
  int relChangeLeft;
  int relChangeRight;
  int peakLeft;
  int peakRight;

  factory RVA(String label, Uint8List data) {
    final incrementFlags = data[0];
    if (incrementFlags & 0xFC != 0) {
      throw BadTagDataException('Unknown flags set for increment/decrement.');
    }
    final bitsForVolume = data[1];

    final volumeFieldSize = (bitsForVolume / 8).ceil() * 8;
    int offset = 2;
    final relChangeLeft = readInt(data.getRange(offset, offset + volumeFieldSize));
    offset += volumeFieldSize;
    final relChangeRight = readInt(data.getRange(offset, offset + volumeFieldSize));
    offset += volumeFieldSize;
    final peakLeft = readInt(data.getRange(offset, offset + volumeFieldSize));
    offset += volumeFieldSize;
    final peakRight = readInt(data.getRange(offset, offset + volumeFieldSize));

    return RVA._(incrementFlags, bitsForVolume, relChangeLeft, relChangeRight, peakLeft, peakRight,
        label, data);
  }

  RVA._(this.incrementFlags, this.bitsForVolume, this.relChangeLeft, this.relChangeRight,
      this.peakLeft, this.peakRight, String label, Uint8List data) : super(label, data);
}


/// EQU: Equalisation
class EQU extends ID3Frame {
  int adjustmentBits;
  Uint8List equCurve;

  EQU(String label, Uint8List data) : adjustmentBits = data[0],
      equCurve = getViewRegion(data, start: 1), super(label, data);
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

  REV(String label, Uint8List data)
      : reverbLeft = readInt(data.getRange(0, 2)),
        reverbRight = readInt(data.getRange(2, 4)),
        bounceLeft = data[4], bounceRight = data[5],
        feedbackLL = data[6], feedbackLR = data[7],
        feedbackRR = data[8], feedbackRL = data[9],
        premixLR = data[10], premixRL = data[11],
        super(label, data);
}


/// PIC: Attached picture.
class PIC extends ID3Frame {
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
  Uint8List imageData;

  factory PIC(String label, Uint8List data) {
    int encodingByte = data[0];
    final imageFormat = String.fromCharCodes(data.getRange(1, 4));
    int pictureType = data[4];

    int nullSeparator = data.indexOf(0, 4);
    final rawDescription = getViewRegion(data, start: 4, end: nullSeparator);
    final imageData = getViewRegion(data, start: nullSeparator + 1);
    return PIC._(imageFormat, pictureType, decodeByEncodingByte(rawDescription, encodingByte),
        imageData, label, data);
  }

  PIC._(this.imageFormat, this.pictureType, this.description, this.imageData,
      String label, Uint8List data) : super(label, data);
}


/// GEO: General encapsulated object.
class GEO extends ID3Frame {
  String mimeType;
  String filename;
  String description;
  Uint8List rawData;

  factory GEO(String label, Uint8List data) {
    int encodingByte = data[0];
    int afterMimeType = data.indexOf(0, 1);
    int afterFilename = data.indexOf(0, afterMimeType + 1);
    int afterDescription = data.indexOf(0, afterFilename + 1);

    final rawMimeType = getViewRegion(data, start: 1, end: afterMimeType);
    final rawFilename = getViewRegion(data, start: afterMimeType + 1, end: afterFilename);
    final rawDescription = getViewRegion(data, start: afterFilename + 1, end: afterDescription);
    final rawData = getViewRegion(data, start: afterDescription + 1);

    return GEO._(
      decodeByEncodingByte(rawMimeType, encodingByte),
      decodeByEncodingByte(rawFilename, encodingByte),
      decodeByEncodingByte(rawDescription, encodingByte),
      rawData,
      label,
      data,
    );
  }

  GEO._(this.mimeType, this.filename, this.description, this.rawData, String label, Uint8List data)
      : super(label, data);
}


/// CNT: Play counter.
class CNT extends ID3Frame {
  int playCount;

  CNT(String label, Uint8List data) : playCount = readInt(data), super(label, data);
}


/// POP: Popularimeter.
class POP extends ID3Frame {
  String email;
  int rating;
  int playCount;

  factory POP(String label, Uint8List data) {
    int nullSeparator = data.indexOf(0);
    final email = String.fromCharCodes(data.getRange(0, nullSeparator));
    int rating = data[nullSeparator + 1];
    int playCount;
    if (nullSeparator + 2 != data.length) {
      playCount = readInt(data.getRange(nullSeparator + 2, data.length));
    } else {
      playCount = null;
    }

    return POP._(email, rating, playCount, label, data);
  }

  POP._(this.email, this.rating, this.playCount, String label, Uint8List data) : super(label, data);
}


/// BUF: Recommended buffer size.
class BUF extends ID3Frame {
  int bufferSize;
  bool embeddedInfo;
  int offsetToNextTag;

  factory BUF(String label, Uint8List data) {
    int bufferSize = readInt(data.getRange(0, 3));
    if (data[3] & 0xFE != 0) {
      throw BadTagDataException('Unknown flags set in the embedded info byte.');
    }
    bool embeddedInfo = data[3] == 1;
    int offset;
    if (data.length != 4) {
      offset = readInt(data.getRange(4, data.length));
    } else {
      offset = null;
    }

    return BUF._(bufferSize, embeddedInfo, offset, label, data);
  }

  BUF._(this.bufferSize, this.embeddedInfo, this.offsetToNextTag, String label, Uint8List data)
      : super(label, data);
}


/// CRM: Encrypted meta frame.
class CRM extends ID3Frame {
  String owner;
  String explanation;
  Uint8List encryptedData;

  factory CRM(String label, Uint8List data) {
    if (data[0] == 0) {
      throw BadTagDataException('First byte is null in CRM frame.');
    }
    int afterOwner = data.indexOf(0);
    int afterExplanation = data.indexOf(0, afterOwner + 1);

    final owner = String.fromCharCodes(data.getRange(0, afterOwner));
    final explanation = String.fromCharCodes(data.getRange(afterOwner + 1, afterExplanation));
    final encryptedData = Uint8List.view(data.buffer, afterExplanation + 1);

    return CRM._(owner, explanation, encryptedData, label, data);
  }

  CRM._(this.owner, this.explanation, this.encryptedData, String label, Uint8List data)
      : super(label, data);
}


/// CRA: Audio encryption.
class CRA extends ID3Frame {
  String owner;
  int previewStart;
  int previewLength;
  Uint8List encryptionInfo;

  factory CRA(String label, Uint8List data) {
    if (data[0] == 0) {
      throw BadTagDataException('First byte is null in CRA frame.');
    }
    int afterOwner = data.indexOf(0);
    int previewStart = readInt(data.getRange(afterOwner + 1, afterOwner + 3));
    int previewLength = readInt(data.getRange(afterOwner + 3, afterOwner + 5));

    final owner = String.fromCharCodes(data.getRange(0, afterOwner));
    final encryptionInfo = getViewRegion(data, start: afterOwner + 5);

    return CRA._(owner, previewStart, previewLength, encryptionInfo, label, data);
  }

  CRA._(this.owner, this.previewStart, this.previewLength, this.encryptionInfo, String label,
      Uint8List data) : super(label, data);
}


/// LNK: Linked information.
class LNK extends ID3Frame {
  String linkedFrame;
  String url;
  String idData;

  factory LNK(String label, Uint8List data) {
    final linkedFrame = String.fromCharCodes(data.getRange(0, 3));
    int afterUrl = data.indexOf(0, 3);
    final url = String.fromCharCodes(data.getRange(3, afterUrl));
    final idData = String.fromCharCodes(data.getRange(afterUrl + 1, data.length));

    return LNK._(linkedFrame, url, idData, label, data);
  }

  LNK._(this.linkedFrame, this.url, this.idData, String label, Uint8List data) : super(label, data);
}
