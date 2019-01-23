import 'dart:typed_data';

import 'tag_types.dart';
import 'exceptions.dart';
import 'helpers.dart';

const iso_8859_1 = 0;


/// UFID: Unique file identifier.
class UFID extends ID3Frame {
  String owner;
  Uint8List identifier;

  UFID.parse(String label, V23FrameFlags flags, Uint8List data) : super('UFID', flags: flags) {
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
    V23FrameFlags flags
  }) : super('UFID', flags: flags);
}


/// Frame that mainly contains text.
///
/// This is an interface so it does not refer to any actual frames.
abstract class PlainTextFrame {
  String text;
  int encoding;
}


/// T000-TZZZ, excluding TXXX: Text information frames.
///
/// Refers to the following frames:
/// - TALB: Album/Movie/Show title
/// - TBPM: BPM
/// - TCOM: Composer(s)
/// - TCON: Content type
/// - TCOP: Copyright message
/// - TDAT: Date
/// - TDLY: Playlist delay
/// - TENC: Encoded by
/// - TEXT: Lyricist(s)/Text writer(s)
/// - TFLT: File type
/// - TIME: Time
/// - TIT1: Content group description
/// - TIT2: Title/Songname/Content description
/// - TIT3: Subtitle/Description refinement
/// - TKEY: Initial key
/// - TLAN: Language(s)
/// - TLEN: Length of audio
/// - TMED: Media type
/// - TOAL: Original album/movie/show title
/// - TOFN: Original filename
/// - TOLY: Original lyricist(s)/text writer(s)
/// - TOPE: Original artist(s)/performer(s)
/// - TORY: Original release year
/// - TOWN: File owner/licensee
/// - TPE1: Lead artist(s)/Lead performer(s)/Soloist(s)/Performing group
/// - TPE2: Band/Orchestra/Accompaniment
/// - TPE3: Conductor
/// - TPE4: Interpreted, remixed, or otherwise modified by
/// - TPOS: Part of a set
/// - TPUB: Publisher
/// - TRCK: Track number/Position in set
/// - TRDA: Recording dates
/// - TRSN: Internet radio station name
/// - TRSO: Internet radio station owner
/// - TSIZ: Size
/// - TSRC: ISRC
/// - TSSE: Software/Hardware and settings used for encoding
/// - TYER: Year
class TextFrame extends ID3Frame implements PlainTextFrame {
  int encoding;
  String text;

  TextFrame.parse(String label, V23FrameFlags flags, Uint8List data)
      : text = decodeByEncodingByte(getViewRegion(data, start: 1), data[0]), encoding = data[0],
        super(label, flags: flags);

  TextFrame(String label, {
    this.text,
    this.encoding = iso_8859_1,
    V23FrameFlags flags,
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

  UserDefinedFrame.parse(String label, V23FrameFlags flags, Uint8List data)
      : super(label, flags: flags) {
    var parser = BinaryParser(data);
    encoding = parser.getByte();
    description = parser.getStringUntilNull(encoding: encoding);
    text = parser.getStringUntilEnd(encoding: encoding);
  }

  UserDefinedFrame(String label, {
    this.description,
    this.text,
    this.encoding = iso_8859_1,
    V23FrameFlags flags,
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
/// - WORS: Official internet radio station homepage
/// - WPAY: Payment
/// - WPUB: Publishers official webpage
class UrlFrame extends ID3Frame implements PlainTextFrame {
  String text;
  int encoding;

  UrlFrame.parse(String label, V23FrameFlags flags, Uint8List data)
      : text = String.fromCharCodes(data), encoding = iso_8859_1, super(label, flags: flags);

  UrlFrame(String label, {
    this.text,
    V23FrameFlags flags,
  }) : encoding = iso_8859_1, super(label, flags: flags);
}


/// IPLS: Involved people list.
class IPLS extends ID3Frame {
  int encoding;
  Map<String, String> involvement;

  IPLS.parse(String label, V23FrameFlags flags, Uint8List data) : super('IPLS', flags: flags) {
    var parser = BinaryParser(data);
    encoding = parser.getByte();

    involvement = Map<String, String>();

    while (parser.hasMoreData()) {
      var key = parser.getStringUntilNull(encoding: encoding);
      var value = parser.getStringUntilNull(encoding: encoding);
      involvement[key] = value;
    }
  }

  IPLS({
    this.involvement,
    this.encoding = iso_8859_1,
    V23FrameFlags flags
  }) : super('IPLS', flags: flags);
}


/// Frame that mainly contains binary data.
///
/// The parsing of that data is currently not in the roadmap for this library, but may come later.
/// This is an interface so it does not refer to any actual frames.
class BinaryFrame {
  Uint8List data;
}


/// MCDI: Music CD Identifier.
class MCDI extends ID3Frame implements BinaryFrame {
  Uint8List data;

  MCDI.parse(String label, V23FrameFlags flags, Uint8List data)
      : data = data, super('MCDI', flags: flags);

  MCDI({this.data, V23FrameFlags flags}) : super('MCDI', flags: flags);
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

  TimestampFrame.parse(String label, V23FrameFlags flags, Uint8List data)
      : timestampType = data[0], data = getViewRegion(data, start: 1), super(label, flags: flags);

  TimestampFrame(String label, {this.timestampType, this.data, V23FrameFlags flags})
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

  MLLT.parse(String label, V23FrameFlags flags, Uint8List data) : super('MLLT') {
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
    V23FrameFlags flags
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

  LangDescTextFrame.parse(String label, V23FrameFlags flags, Uint8List data)
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
    this.encoding = iso_8859_1,
    V23FrameFlags flags,
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

  SYLT.parse(String label, V23FrameFlags flags, Uint8List data) : super('SYLT', flags: flags) {
    var parser = BinaryParser(data);
    encoding = parser.getByte();
    language = parser.getString(size: 3);
    timestampType = parser.getByte();
    contentType = parser.getByte();
    descriptor = parser.getStringUntilNull(encoding: encoding);
    this.data = parser.getBytesUntilEnd();
  }

  SYLT({this.language, this.timestampType, this.contentType, this.descriptor,
      this.data, this.encoding = iso_8859_1, V23FrameFlags flags}) : super('SYLT', flags: flags);
}


/// RVAD: Relative volume adjustment.
class RVAD extends ID3Frame {
  int incrementFlags;
  int bitsForVolume;
  int relChangeLeft;
  int relChangeRight;
  int peakLeft;
  int peakRight;
  int relChangeRightBack;
  int relChangeLeftBack;
  int peakRightBack;
  int peakLeftBack;
  int relChangeCenter;
  int peakCenter;
  int relChangeBass;
  int peakBass;

  RVAD.parse(String label, V23FrameFlags flags, Uint8List data) : super('RVAD', flags: flags) {
    var parser = BinaryParser(data);
    incrementFlags = parser.getByte();
    if (incrementFlags & 0xC0 != 0) {  // 0xC0 == 0b11000000
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

    if (parser.hasMoreData()) {
      relChangeRightBack = parser.getInt(size: volumeFieldSize);
      relChangeLeftBack = parser.getInt(size: volumeFieldSize);
      peakRightBack = parser.getInt(size: volumeFieldSize);
      peakLeftBack = parser.getInt(size: volumeFieldSize);
    }

    if (parser.hasMoreData()) {
      relChangeCenter = parser.getInt(size: volumeFieldSize);
      peakCenter = parser.getInt(size: volumeFieldSize);
    }

    if (parser.hasMoreData()) {
      relChangeBass = parser.getInt(size: volumeFieldSize);
      peakBass = parser.getInt(size: volumeFieldSize);
    }
  }

  RVAD({
    this.incrementFlags,
    this.bitsForVolume,
    this.relChangeLeft,
    this.relChangeRight,
    this.peakLeft,
    this.peakRight,
    this.relChangeRightBack,
    this.relChangeLeftBack,
    this.peakRightBack,
    this.peakLeftBack,
    this.relChangeCenter,
    this.peakCenter,
    this.relChangeBass,
    this.peakBass,
    V23FrameFlags flags,
  }) : super('RVAD', flags: flags);
}


/// EQUA: Equalisation.
class EQUA extends ID3Frame implements BinaryFrame {
  int adjustmentBits;
  Uint8List data;

  EQUA.parse(String label, V23FrameFlags flags, Uint8List data) : adjustmentBits = data[0],
      data = getViewRegion(data, start: 1), super('EQUA', flags: flags);

  EQUA({this.adjustmentBits, this.data, V23FrameFlags flags}) : super('EQUA', flags: flags);
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

  RVRB.parse(String label, V23FrameFlags flags, Uint8List data)
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
    V23FrameFlags flags,
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

  APIC.parse(String label, V23FrameFlags flags, Uint8List data) : super('APIC', flags: flags) {
    var parser = BinaryParser(data);
    encoding = parser.getByte();
    mimeType = parser.getStringUntilNull();
    pictureType = parser.getByte();
    description = parser.getStringUntilNull(encoding: encoding);
    this.data = parser.getBytesUntilEnd();
  }

  APIC({this.mimeType, this.pictureType, this.description = '', this.data, V23FrameFlags flags})
      : super('APIC', flags: flags);
}


/// GEOB: General encapsulated object.
class GEOB extends ID3Frame implements BinaryFrame {
  int encoding;
  String mimeType;
  String filename;
  String description;
  Uint8List data;

  GEOB.parse(String label, V23FrameFlags flags, Uint8List data) : super('GEOB', flags: flags) {
    var parser = BinaryParser(data);
    int encoding = parser.getByte();

    mimeType = parser.getStringUntilNull(encoding: encoding);
    filename = parser.getStringUntilNull(encoding: encoding);
    description = parser.getStringUntilNull();
    this.data = parser.getBytesUntilEnd();
  }

  GEOB({this.mimeType, this.filename, this.description, this.data, V23FrameFlags flags})
      : super('GEOB', flags: flags);
}


/// PCNT: Play counter.
class PCNT extends ID3Frame {
  int playCount;

  PCNT.parse(String label, V23FrameFlags flags, Uint8List data)
      : playCount = readInt(data), super('PCNT', flags: flags);

  PCNT({this.playCount, V23FrameFlags flags}) : super('PCNT', flags: flags);
}


/// POPM: Popularimeter.
class POPM extends ID3Frame {
  String email;
  int rating;
  int playCount;

  POPM.parse(String label, V23FrameFlags flags, Uint8List data) : super('POPM', flags: flags) {
    var parser = BinaryParser(data);
    email = parser.getStringUntilNull();
    rating = parser.getByte();

    if (parser.hasMoreData()) {
      playCount = parser.getIntUntilEnd();
    }
  }

  POPM({this.email, this.rating, this.playCount, V23FrameFlags flags})
      : super('POPM', flags: flags);
}


/// RBUF: Recommended buffer size.
class RBUF extends ID3Frame {
  int bufferSize;
  bool embeddedInfo;
  int offsetToNextTag;

  RBUF.parse(String label, V23FrameFlags flags, Uint8List data) : super('RBUF', flags: flags) {
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

  RBUF({this.bufferSize, this.embeddedInfo, this.offsetToNextTag, V23FrameFlags flags})
      : super('RBUF', flags: flags);
}


/// AENC: Audio encryption.
class AENC extends ID3Frame implements BinaryFrame {
  String owner;
  int previewStart;
  int previewLength;
  Uint8List data;

  AENC.parse(String label, V23FrameFlags flags, Uint8List data) : super('AENC', flags: flags) {
    var parser = BinaryParser(data);
    if (parser.nextByte() == 0) {
      throw BadTagDataException('Owner identifier cannot be empty.');
    }
    owner = parser.getStringUntilNull();
    previewStart = parser.getInt(size: 2);
    previewLength = parser.getInt(size: 2);
    this.data = parser.getBytesUntilEnd();
  }

  AENC({this.owner, this.previewStart, this.previewLength, this.data, V23FrameFlags flags})
      : super('AENC', flags: flags);
}


/// LINK: Linked information.
class LINK extends ID3Frame {
  String linkedFrame;
  String url;
  List<String> idData;

  LINK.parse(String label, V23FrameFlags flags, Uint8List data) : super('LINK', flags: flags) {
    var parser = BinaryParser(data);
    linkedFrame = parser.getString(size: 4);
    url = parser.getStringUntilNull();
    idData = parser.getStringsUntilEnd();
  }

  LINK({this.linkedFrame, this.url, this.idData, V23FrameFlags flags})
      : super('LINK', flags: flags);
}


/// USER: Terms of use frame.
class USER extends ID3Frame implements PlainTextFrame {
  int encoding;
  String text;
  String language;

  USER.parse(String label, V23FrameFlags flags, Uint8List data) : super('USER', flags: flags) {
    var parser = BinaryParser(data);
    encoding = parser.getByte();
    language = parser.getString(size: 3);
    text = parser.getStringUntilEnd(encoding: encoding);
  }

  USER({this.text, this.encoding = iso_8859_1, this.language, V23FrameFlags flags})
      : super('USER', flags: flags);
}


/// OWNE: Ownership frame.
class OWNE extends ID3Frame {
  int encoding;
  String price;
  DateTime dateOfPurchase;
  String seller;

  OWNE.parse(String label, V23FrameFlags flags, Uint8List data) : super('OWNE', flags: flags) {
    var parser = BinaryParser(data);
    encoding = parser.getByte();
    price = parser.getStringUntilNull();
    dateOfPurchase = parseDate(parser.getString(size: 8));
    seller = parser.getStringUntilEnd(encoding: encoding);
  }

  OWNE({this.price, this.dateOfPurchase, this.seller, this.encoding, V23FrameFlags flags})
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

  COMR.parse(String label, V23FrameFlags flags, Uint8List data) : super('COMR', flags: flags) {
    var parser = BinaryParser(data);
    encoding = parser.getByte();
    price = parser.getStringUntilNull();
    validUntil = parseDate(parser.getString(size: 8));
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
    V23FrameFlags flags
  }) : super('COMR', flags: flags);
}


/// ENCR: Encryption method registration.
class ENCR extends ID3Frame implements BinaryFrame {
  String owner;
  int methodSymbol;
  Uint8List data;

  ENCR.parse(String label, V23FrameFlags flags, Uint8List data) : super('ENCR', flags: flags) {
    var parser = BinaryParser(data);
    owner = parser.getStringUntilNull();
    methodSymbol = parser.getByte();
    this.data = parser.getBytesUntilEnd();
  }

  ENCR({this.owner, this.methodSymbol, this.data, V23FrameFlags flags})
      : super('ENCR', flags: flags);
}


/// GRID: Group ID registration.
class GRID extends ID3Frame implements BinaryFrame {
  String owner;
  int groupSymbol;
  Uint8List data;

  GRID.parse(String label, V23FrameFlags flags, Uint8List data) : super('GRID', flags: flags) {
    var parser = BinaryParser(data);
    owner = parser.getStringUntilNull();
    groupSymbol = parser.getByte();
    this.data = parser.getBytesUntilEnd();
  }

  GRID({this.owner, this.groupSymbol, this.data, V23FrameFlags flags})
      : super('GRID', flags: flags);
}


/// PRIV: Private frame.
class PRIV extends ID3Frame implements BinaryFrame {
  String owner;
  Uint8List data;

  PRIV.parse(String label, V23FrameFlags flags, Uint8List data) : super('PRIV', flags: flags) {
    var parser = BinaryParser(data);
    owner = parser.getStringUntilNull();
    this.data = parser.getBytesUntilEnd();
  }

  PRIV({this.owner, this.data, V23FrameFlags flags}) : super('PRIV', flags: flags);
}
