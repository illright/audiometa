import 'dart:typed_data';

import 'tag_types.dart';
import 'exceptions.dart';
import 'helpers.dart';


/// UFID: Unique file identifier.
class UFID extends ID3Frame {
  String owner;
  Uint8List identifier;

  UFID.parse(String label, V24FrameFlags flags, Uint8List data) : super('UFID', flags: flags) {
    var parser = BinaryParser(data);
    if (parser.nextByte() == 0) {
      throw BadTagDataException('Owner identifier cannot be empty.');
    }

    owner = parser.getStringUntilNull();
    identifier = parser.getBytesUntilEnd();
  }

  UFID({
    this.owner,
    this.identifier,
    V24FrameFlags flags
  }) : super('UFID', flags: flags);
}


/// Frame that mainly contains several text strings.
///
/// This is an interface so it does not refer to any actual frames.
abstract class MulitpleTextFrame extends PlainTextFrame {
  List<String> values;
  String text;
  int encoding;
}


/// T000-TZZZ, excluding TXXX: Text information frames.
///
/// Refers to the following frames:
/// - TIT1: Content group description
/// - TIT2: Title/Songname/Content description
/// - TIT3: Subtitle/Description refinement
/// - TALB: Album/Movie/Show title
/// - TOAL: Original album/movie/show title
/// - TRCK: Track number/Position in set
/// - TPOS: Part of a set
/// - TSST: Set subtitle
/// - TSRC: ISRC
/// - TPE1: Lead artist/Lead performer/Soloist/Performing group
/// - TPE2: Band/Orchestra/Accompaniment
/// - TPE3: Conductor
/// - TPE4: Interpreted, remixed, or otherwise modified by
/// - TOPE: Original artist/performer
/// - TEXT: Lyricist/Text writer
/// - TOLY: Original lyricist/text writer
/// - TCOM: Composer
/// - TMCL: Musician credits list
/// - TIPL: Involved people list
/// - TENC: Encoded by
/// - TBPM: BPM
/// - TLEN: Length
/// - TKEY: Initial key
/// - TLAN: Language
/// - TCON: Content type
/// - TFLT: File type
/// - TMED: Media type
/// - TCOP: Copyright message
/// - TPRO: Produced notice
/// - TPUB: Publisher
/// - TOWN: File owner/licensee
/// - TRSN: Internet radio station name
/// - TRSO: Internet radio station owner
/// - TOFN: Original filename
/// - TDLY: Playlist delay
/// - TDEN: Encoding time
/// - TDOR: Original release time
/// - TDRC: Recording time
/// - TDRL: Release time
/// - TDTG: Tagging time
/// - TSSE: Software/Hardware and settings used for encoding
/// - TSOA: Album sort order
/// - TSOP: Performer sort order
/// - TSOT: Title sort order
class TextFrame extends ID3Frame implements MulitpleTextFrame {
  int encoding;
  List<String> values;
  String get text => values.first;
  void set text(String newValue) {
    values.first = newValue;
  }

  TextFrame.parse(String label, V24FrameFlags flags, Uint8List data) : super(label, flags: flags) {
    var parser = BinaryParser(data);
    encoding = parser.getByte();
    values = parser.getStringsUntilEnd(encoding: encoding);
  }


  TextFrame(String label, {
    this.values,
    this.encoding = utf8,
    V24FrameFlags flags,
  }) : super(label, flags: flags);
}


/// User defined frames.
///
/// Refers to the following frames:
/// - TXXX: User defined text information frame
/// - WXXX: User defined URL link frame
class UserDefinedFrame extends ID3Frame implements PlainTextFrame {
  int encoding;
  String description;
  String text;

  UserDefinedFrame.parse(String label, V24FrameFlags flags, Uint8List data)
      : super(label, flags: flags) {
    var parser = BinaryParser(data);
    encoding = parser.getByte();
    description = parser.getStringUntilNull(encoding: encoding);
    text = parser.getStringUntilEnd(encoding: encoding);
  }

  UserDefinedFrame(String label, {
    this.description,
    this.text,
    this.encoding = utf8,
    V24FrameFlags flags,
  }) : super(label, flags: flags);
}


/// W000-WZZZ, excluding WXXX: URL link frames.
///
/// Refers to the following frames:
/// - WCOM: Commercial information
/// - WCOP: Copyright/Legal information
/// - WOAF: Official audio file webpage
/// - WOAR: Official artist/performer webpage
/// - WOAS: Official audio source webpage
/// - WORS: Official Internet radio station homepage
/// - WPAY: Payment
/// - WPUB: Publishers official webpage
class UrlFrame extends ID3Frame implements PlainTextFrame {
  String text;
  int encoding;

  UrlFrame.parse(String label, V24FrameFlags flags, Uint8List data)
      : text = String.fromCharCodes(data), encoding = iso_8859_1, super(label, flags: flags);

  UrlFrame(String label, {
    this.text,
    V24FrameFlags flags,
  }) : encoding = utf8, super(label, flags: flags);
}


/// MCDI: Music CD Identifier.
class MCDI extends ID3Frame implements BinaryFrame {
  Uint8List data;

  MCDI.parse(String label, V24FrameFlags flags, Uint8List data)
      : data = data, super('MCDI', flags: flags);

  MCDI({this.data, V24FrameFlags flags}) : super('MCDI', flags: flags);
}


/// Frame that includes a timestamp of a certain type.
///
/// Refers to the following frames:
/// - ETCO: Event timing codes
/// - SYTC: Synced tempo codes
/// - POSS: Position synchronisation frame
class TimestampFrame extends ID3Frame implements BinaryFrame {
  int timestampType;
  Uint8List data;

  TimestampFrame.parse(String label, V24FrameFlags flags, Uint8List data)
      : timestampType = data[0], data = getViewRegion(data, start: 1), super(label, flags: flags);

  TimestampFrame(String label, {this.timestampType, this.data, V24FrameFlags flags})
      : super(label, flags: flags);
}


/// MLLT: MPEG location lookup table.
class MLLT extends ID3Frame implements BinaryFrame {
  int framesBetweenRef;
  int bytesBetweenRef;
  int msBetweenRef;
  int bitsForByteDev;
  int bitsForMsDev;
  Uint8List data;

  MLLT.parse(String label, V24FrameFlags flags, Uint8List data) : super('MLLT') {
    var parser = BinaryParser(data);
    framesBetweenRef = parser.getInt(size: 2);
    bytesBetweenRef = parser.getInt(size: 3);
    msBetweenRef = parser.getInt(size: 3);
    bitsForByteDev = parser.getByte();
    bitsForMsDev = parser.getByte();
    this.data = parser.getBytesUntilEnd();
  }

  MLLT({
    this.framesBetweenRef,
    this.bytesBetweenRef,
    this.msBetweenRef,
    this.bitsForByteDev,
    this.bitsForMsDev,
    this.data,
    V24FrameFlags flags
  }) : super('MLLT', flags: flags);
}


/// A text frame that contains information about the language and a content description.
///
/// Refers to the following frames:
/// - USLT: Unsynchronised lyrics/text transcription
/// - COMM: Comments
class LangDescTextFrame extends ID3Frame implements PlainTextFrame {
  int encoding;
  String language;
  String description;
  String text;

  LangDescTextFrame.parse(String label, V24FrameFlags flags, Uint8List data)
      : super(label, flags: flags) {
    var parser = BinaryParser(data);
    encoding = parser.getByte();
    language = parser.getString(size: 3);
    description = parser.getStringUntilNull(encoding: encoding);
    text = parser.getStringUntilEnd(encoding: encoding);
  }

  LangDescTextFrame(String label, {
    this.language,
    this.description,
    this.text,
    this.encoding = utf8,
    V24FrameFlags flags,
  }) : super(label, flags: flags);
}


/// SYLT: Synchronised lyrics/text.
class SYLT extends ID3Frame implements BinaryFrame {
  int encoding;
  String language;
  int timestampType;
  int contentType;
  String descriptor;
  Uint8List data;

  SYLT.parse(String label, V24FrameFlags flags, Uint8List data) : super('SYLT', flags: flags) {
    var parser = BinaryParser(data);
    encoding = parser.getByte();
    language = parser.getString(size: 3);
    timestampType = parser.getByte();
    contentType = parser.getByte();
    descriptor = parser.getStringUntilNull(encoding: encoding);
    this.data = parser.getBytesUntilEnd();
  }

  SYLT({this.language, this.timestampType, this.contentType, this.descriptor,
      this.data, this.encoding = utf8, V24FrameFlags flags}) : super('SYLT', flags: flags);
}


/// RVA2: Relative volume adjustment.
class RVA2 extends ID3Frame implements BinaryFrame {
  String identifier;
  Uint8List data;

  RVA2.parse(String label, V24FrameFlags flags, Uint8List data) : super('RVA2', flags: flags) {
    var parser = BinaryParser(data);
    identifier = parser.getStringUntilNull();
    data = parser.getBytesUntilEnd();
  }

  RVA2({
    this.identifier,
    this.data,
    V24FrameFlags flags,
  }) : super('RVA2', flags: flags);
}


/// EQU2: Equalisation.
class EQU2 extends ID3Frame implements BinaryFrame {
  int interpolationMethod;
  String identifier;
  Uint8List data;

  EQU2.parse(String label, V24FrameFlags flags, Uint8List data) : super('EQU2', flags: flags) {
    var parser = BinaryParser(data);
    interpolationMethod = parser.getByte();
    identifier = parser.getStringUntilNull();
    data = parser.getBytesUntilEnd();
  }

  EQU2({this.interpolationMethod, this.identifier, this.data, V24FrameFlags flags})
      : super('EQU2', flags: flags);
}


/// RVRB: Reverb.
class RVRB extends ID3Frame {
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

  RVRB.parse(String label, V24FrameFlags flags, Uint8List data)
      : reverbLeft = readInt(data.getRange(0, 2)),
        reverbRight = readInt(data.getRange(2, 4)),
        bounceLeft = data[4], bounceRight = data[5],
        feedbackLL = data[6], feedbackLR = data[7],
        feedbackRR = data[8], feedbackRL = data[9],
        premixLR = data[10], premixRL = data[11],
        super('RVRB', flags: flags);

  RVRB({
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
    V24FrameFlags flags,
  }) : super('RVRB', flags: flags);
}


/// APIC: Attached picture.
class APIC extends ID3Frame implements BinaryFrame {
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
  String mimeType;
  int pictureType;
  String description;
  Uint8List data;

  APIC.parse(String label, V24FrameFlags flags, Uint8List data) : super('APIC', flags: flags) {
    var parser = BinaryParser(data);
    encoding = parser.getByte();
    mimeType = parser.getStringUntilNull();
    pictureType = parser.getByte();
    description = parser.getStringUntilNull(encoding: encoding);
    this.data = parser.getBytesUntilEnd();
  }

  APIC({this.mimeType, this.pictureType, this.description = '', this.data, V24FrameFlags flags})
      : super('APIC', flags: flags);
}


/// GEOB: General encapsulated object.
class GEOB extends ID3Frame implements BinaryFrame {
  int encoding;
  String mimeType;
  String filename;
  String description;
  Uint8List data;

  GEOB.parse(String label, V24FrameFlags flags, Uint8List data) : super('GEOB', flags: flags) {
    var parser = BinaryParser(data);
    int encoding = parser.getByte();

    mimeType = parser.getStringUntilNull(encoding: encoding);
    filename = parser.getStringUntilNull(encoding: encoding);
    description = parser.getStringUntilNull();
    this.data = parser.getBytesUntilEnd();
  }

  GEOB({this.mimeType, this.filename, this.description, this.data, V24FrameFlags flags})
      : super('GEOB', flags: flags);
}


/// PCNT: Play counter.
class PCNT extends ID3Frame {
  int playCount;

  PCNT.parse(String label, V24FrameFlags flags, Uint8List data)
      : playCount = readInt(data), super('PCNT', flags: flags);

  PCNT({this.playCount, V24FrameFlags flags}) : super('PCNT', flags: flags);
}


/// POPM: Popularimeter.
class POPM extends ID3Frame {
  String email;
  int rating;
  int playCount;

  POPM.parse(String label, V24FrameFlags flags, Uint8List data) : super('POPM', flags: flags) {
    var parser = BinaryParser(data);
    email = parser.getStringUntilNull();
    rating = parser.getByte();

    if (parser.hasMoreData()) {
      playCount = parser.getIntUntilEnd();
    }
  }

  POPM({this.email, this.rating, this.playCount, V24FrameFlags flags})
      : super('POPM', flags: flags);
}


/// RBUF: Recommended buffer size.
class RBUF extends ID3Frame {
  int bufferSize;
  bool embeddedInfo;
  int offsetToNextTag;

  RBUF.parse(String label, V24FrameFlags flags, Uint8List data) : super('RBUF', flags: flags) {
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

  RBUF({this.bufferSize, this.embeddedInfo, this.offsetToNextTag, V24FrameFlags flags})
      : super('RBUF', flags: flags);
}


/// AENC: Audio encryption.
class AENC extends ID3Frame implements BinaryFrame {
  String owner;
  int previewStart;
  int previewLength;
  Uint8List data;

  AENC.parse(String label, V24FrameFlags flags, Uint8List data) : super('AENC', flags: flags) {
    var parser = BinaryParser(data);
    if (parser.nextByte() == 0) {
      throw BadTagDataException('Owner identifier cannot be empty.');
    }
    owner = parser.getStringUntilNull();
    previewStart = parser.getInt(size: 2);
    previewLength = parser.getInt(size: 2);
    this.data = parser.getBytesUntilEnd();
  }

  AENC({this.owner, this.previewStart, this.previewLength, this.data, V24FrameFlags flags})
      : super('AENC', flags: flags);
}


/// LINK: Linked information.
class LINK extends ID3Frame {
  String linkedFrame;
  String url;
  List<String> idData;

  LINK.parse(String label, V24FrameFlags flags, Uint8List data) : super('LINK', flags: flags) {
    var parser = BinaryParser(data);
    linkedFrame = parser.getString(size: 4);
    url = parser.getStringUntilNull();
    idData = parser.getStringsUntilEnd();
  }

  LINK({this.linkedFrame, this.url, this.idData, V24FrameFlags flags})
      : super('LINK', flags: flags);
}


/// USER: Terms of use frame.
class USER extends ID3Frame implements PlainTextFrame {
  int encoding;
  String text;
  String language;

  USER.parse(String label, V24FrameFlags flags, Uint8List data) : super('USER', flags: flags) {
    var parser = BinaryParser(data);
    encoding = parser.getByte();
    language = parser.getString(size: 3);
    text = parser.getStringUntilEnd(encoding: encoding);
  }

  USER({this.text, this.encoding = utf8, this.language, V24FrameFlags flags})
      : super('USER', flags: flags);
}


/// OWNE: Ownership frame.
class OWNE extends ID3Frame {
  int encoding;
  String price;
  DateTime dateOfPurchase;
  String seller;

  OWNE.parse(String label, V24FrameFlags flags, Uint8List data) : super('OWNE', flags: flags) {
    var parser = BinaryParser(data);
    encoding = parser.getByte();
    price = parser.getStringUntilNull();
    dateOfPurchase = parseDateYmd(parser.getString(size: 8));
    seller = parser.getStringUntilEnd(encoding: encoding);
  }

  OWNE({this.price, this.dateOfPurchase, this.seller, this.encoding, V24FrameFlags flags})
      : super('OWNE', flags: flags);
}


/// COMR: Commercial frame.
class COMR extends ID3Frame {
  static const other = 0;
  static const cdAlbum = 1;
  static const compressedCD = 2;
  static const fileInternet = 3;
  static const streamInternet = 4;
  static const noteSheets = 5;
  static const noteSheetsBook = 6;
  static const otherMedia = 7;
  static const merch = 8;

  int encoding;
  String price;
  DateTime validUntil;
  String contactUrl;
  int receivedAs;
  String seller;
  String description;
  String logoMimeType;
  Uint8List logo;

  COMR.parse(String label, V24FrameFlags flags, Uint8List data) : super('COMR', flags: flags) {
    var parser = BinaryParser(data);
    encoding = parser.getByte();
    price = parser.getStringUntilNull();
    validUntil = parseDateYmd(parser.getString(size: 8));
    contactUrl = parser.getStringUntilNull();
    receivedAs = parser.getByte();
    seller = parser.getStringUntilNull(encoding: encoding);
    description = parser.getStringUntilNull(encoding: encoding);
    if (parser.hasMoreData()) {
      logoMimeType = parser.getStringUntilNull(encoding: encoding);
      logo = parser.getBytesUntilEnd();
    }
  }

  COMR({
    this.price,
    this.validUntil,
    this.contactUrl,
    this.receivedAs,
    this.seller,
    this.description,
    this.logoMimeType,
    this.logo,
    this.encoding,
    V24FrameFlags flags
  }) : super('COMR', flags: flags);
}


/// ENCR: Encryption method registration.
class ENCR extends ID3Frame implements BinaryFrame {
  String owner;
  int methodSymbol;
  Uint8List data;

  ENCR.parse(String label, V24FrameFlags flags, Uint8List data) : super('ENCR', flags: flags) {
    var parser = BinaryParser(data);
    owner = parser.getStringUntilNull();
    methodSymbol = parser.getByte();
    this.data = parser.getBytesUntilEnd();
  }

  ENCR({this.owner, this.methodSymbol, this.data, V24FrameFlags flags})
      : super('ENCR', flags: flags);
}


/// GRID: Group ID registration.
class GRID extends ID3Frame implements BinaryFrame {
  String owner;
  int groupSymbol;
  Uint8List data;

  GRID.parse(String label, V24FrameFlags flags, Uint8List data) : super('GRID', flags: flags) {
    var parser = BinaryParser(data);
    owner = parser.getStringUntilNull();
    groupSymbol = parser.getByte();
    this.data = parser.getBytesUntilEnd();
  }

  GRID({this.owner, this.groupSymbol, this.data, V24FrameFlags flags})
      : super('GRID', flags: flags);
}


/// PRIV: Private frame.
class PRIV extends ID3Frame implements BinaryFrame {
  String owner;
  Uint8List data;

  PRIV.parse(String label, V24FrameFlags flags, Uint8List data) : super('PRIV', flags: flags) {
    var parser = BinaryParser(data);
    owner = parser.getStringUntilNull();
    this.data = parser.getBytesUntilEnd();
  }

  PRIV({this.owner, this.data, V24FrameFlags flags}) : super('PRIV', flags: flags);
}
