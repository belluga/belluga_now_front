import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:belluga_now/application/icons/boora_icons.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Boora icon declarations match the uploaded font asset contract', () {
    final config = _BooraIconConfig.load(
      File('assets/fonts/boora_icons_configs/config.json'),
    );
    final runtimeFont = _TrueTypeFont.load(File(config.runtimeTtf));
    final sourceFont = _TrueTypeFont.load(File(config.sourceTtf));
    final icomoon = _IcoMoonConfig.load(File(config.sourceIcomoonConfig));
    final generatedDart = _GeneratedBooraDart.load(
      File(config.sourceGeneratedDart),
    );

    expect(BooraIcons.fontFamily, config.fontFamily);
    expect(runtimeFont.familyNames, contains(BooraIcons.fontFamily));
    expect(sourceFont.familyNames, contains(BooraIcons.fontFamily));
    expect(File(config.sourceIcomoonConfig).existsSync(), isTrue);
    expect(File(config.sourceGeneratedDart).existsSync(), isTrue);
    expect(File(config.sourceTtf).existsSync(), isTrue);
    expect(File(config.sourceOtf).existsSync(), isTrue);
    expect(File(config.runtimeTtf).existsSync(), isTrue);
    expect(
      File(config.runtimeTtf).readAsBytesSync(),
      equals(File(config.sourceTtf).readAsBytesSync()),
    );
    final runtimeHash =
        sha256.convert(File(config.runtimeTtf).readAsBytesSync()).toString();
    expect(config.runtimeTtf, contains(runtimeHash.substring(0, 8)));
    expect(config.names, containsAll(<String>{'kiosk', 'ice-cream'}));
    expect(config.names.length, BooraIcons.fontIconCount);
    expect(icomoon.fontFamily, config.fontFamily);
    expect(icomoon.codePointByName, config.codePointByName);
    expect(generatedDart.fontFamily, config.fontFamily);
    expect(generatedDart.codePoints, config.codePoints);

    final declaredCodePoints =
        BooraIcons.fontIcons.map((icon) => icon.codePoint).toSet();
    expect(declaredCodePoints, config.codePoints);
    expect(runtimeFont.supportsAll(declaredCodePoints), isTrue);
  });

  test('pubspec registers canonical and legacy Boora icon families', () {
    final config = _BooraIconConfig.load(
      File('assets/fonts/boora_icons_configs/config.json'),
    );
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(pubspec, contains('- family: ${BooraIcons.fontFamily}'));
    for (final legacyFamily in config.legacyFontFamilies) {
      expect(pubspec, contains('- family: $legacyFamily'));
    }
    expect(pubspec, contains('asset: ${config.runtimeTtf}'));
  });
}

class _BooraIconConfig {
  const _BooraIconConfig({
    required this.fontFamily,
    required this.legacyFontFamilies,
    required this.sourceIcomoonConfig,
    required this.sourceGeneratedDart,
    required this.sourceTtf,
    required this.sourceOtf,
    required this.runtimeTtf,
    required this.codePointByName,
  });

  final String fontFamily;
  final Set<String> legacyFontFamilies;
  final String sourceIcomoonConfig;
  final String sourceGeneratedDart;
  final String sourceTtf;
  final String sourceOtf;
  final String runtimeTtf;
  final Map<String, int> codePointByName;

  Set<int> get codePoints => codePointByName.values.toSet();

  Set<String> get names => codePointByName.keys.toSet();

  static _BooraIconConfig load(File file) {
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final glyphs =
        (json['glyphs'] as List<dynamic>).cast<Map<String, dynamic>>();
    final codePointByName = <String, int>{
      for (final glyph in glyphs)
        _nameForGlyph(glyph): _codePointForGlyph(glyph),
    };

    return _BooraIconConfig(
      fontFamily: json['fontFamily'] as String,
      legacyFontFamilies:
          (json['legacyFontFamilies'] as List<dynamic>).cast<String>().toSet(),
      sourceIcomoonConfig: json['sourceIcomoonConfig'] as String,
      sourceGeneratedDart: json['sourceGeneratedDart'] as String,
      sourceTtf: json['sourceTtf'] as String,
      sourceOtf: json['sourceOtf'] as String,
      runtimeTtf: json['runtimeTtf'] as String,
      codePointByName: codePointByName,
    );
  }

  static int _codePointForGlyph(Map<String, dynamic> glyph) {
    final extras = glyph['extras'];
    if (extras is Map<String, dynamic> && extras['codePoint'] is int) {
      return extras['codePoint'] as int;
    }
    return glyph['codePoint'] as int;
  }

  static String _nameForGlyph(Map<String, dynamic> glyph) {
    final extras = glyph['extras'];
    if (extras is Map<String, dynamic> && extras['name'] is String) {
      return extras['name'] as String;
    }
    return glyph['name'] as String;
  }
}

class _IcoMoonConfig {
  const _IcoMoonConfig({
    required this.fontFamily,
    required this.codePointByName,
  });

  final String fontFamily;
  final Map<String, int> codePointByName;

  static _IcoMoonConfig load(File file) {
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final formats =
        (json['formats'] as List<dynamic>).cast<Map<String, dynamic>>();
    final fontFormat = formats.firstWhere(
      (format) {
        final item = format['item'];
        return item is Map<String, dynamic> && item['tag'] == 'ItemFont';
      },
    );
    final item = fontFormat['item'] as Map<String, dynamic>;
    final args = (item['args'] as List<dynamic>).first as Map<String, dynamic>;
    final glyphs =
        (json['glyphs'] as List<dynamic>).cast<Map<String, dynamic>>();

    return _IcoMoonConfig(
      fontFamily:
          (args['fontFamily'] as Map<String, dynamic>)['value'] as String,
      codePointByName: <String, int>{
        for (final glyph in glyphs)
          _BooraIconConfig._nameForGlyph(glyph):
              _BooraIconConfig._codePointForGlyph(glyph),
      },
    );
  }
}

class _GeneratedBooraDart {
  const _GeneratedBooraDart({
    required this.fontFamily,
    required this.codePoints,
  });

  final String fontFamily;
  final Set<int> codePoints;

  static _GeneratedBooraDart load(File file) {
    final source = file.readAsStringSync();
    final familyMatch = RegExp(
      r"static const String _fontFamily = '([^']+)';",
    ).firstMatch(source);
    final iconMatches = RegExp(
      r'static const IconData \w+ = IconData\(0x([0-9a-f]+), fontFamily: _fontFamily\);',
    ).allMatches(source);

    if (familyMatch == null) {
      fail('IcoMoon generated Dart file does not declare _fontFamily.');
    }

    return _GeneratedBooraDart(
      fontFamily: familyMatch.group(1)!,
      codePoints: iconMatches
          .map((match) => int.parse(match.group(1)!, radix: 16))
          .toSet(),
    );
  }
}

class _TrueTypeFont {
  const _TrueTypeFont({
    required this.familyNames,
    required this.supportedCodePointRanges,
  });

  final Set<String> familyNames;
  final List<_CodePointRange> supportedCodePointRanges;

  static _TrueTypeFont load(File file) {
    final bytes = file.readAsBytesSync();
    final data = ByteData.sublistView(bytes);
    final tables = _readTableRecords(data);

    return _TrueTypeFont(
      familyNames: _readFamilyNames(bytes, data, tables['name']!),
      supportedCodePointRanges: _readCodePointRanges(data, tables['cmap']!),
    );
  }

  bool supportsAll(Set<int> codePoints) {
    return codePoints.every(
      (codePoint) => supportedCodePointRanges.any(
        (range) => range.contains(codePoint),
      ),
    );
  }

  static Map<String, _TableRecord> _readTableRecords(ByteData data) {
    final count = data.getUint16(4);
    final tables = <String, _TableRecord>{};
    for (var i = 0; i < count; i += 1) {
      final offset = 12 + (i * 16);
      final tag = String.fromCharCodes(
        List<int>.generate(
          4,
          (index) => data.getUint8(offset + index),
        ),
      );
      tables[tag] = _TableRecord(
        offset: data.getUint32(offset + 8),
      );
    }
    return tables;
  }

  static Set<String> _readFamilyNames(
    Uint8List bytes,
    ByteData data,
    _TableRecord table,
  ) {
    final tableOffset = table.offset;
    final count = data.getUint16(tableOffset + 2);
    final stringOffset = data.getUint16(tableOffset + 4);
    final names = <String>{};

    for (var i = 0; i < count; i += 1) {
      final recordOffset = tableOffset + 6 + (i * 12);
      final platformId = data.getUint16(recordOffset);
      final nameId = data.getUint16(recordOffset + 6);
      if (nameId != 1) {
        continue;
      }

      final length = data.getUint16(recordOffset + 8);
      final offset = data.getUint16(recordOffset + 10);
      final start = tableOffset + stringOffset + offset;
      final nameBytes = bytes.sublist(start, start + length);
      final decoded = platformId == 0 || platformId == 3
          ? _decodeUtf16BigEndian(nameBytes)
          : latin1.decode(nameBytes);
      final normalized = decoded.trim();
      if (normalized.isNotEmpty) {
        names.add(normalized);
      }
    }
    return names;
  }

  static String _decodeUtf16BigEndian(List<int> bytes) {
    final codeUnits = <int>[];
    for (var i = 0; i + 1 < bytes.length; i += 2) {
      codeUnits.add((bytes[i] << 8) | bytes[i + 1]);
    }
    return String.fromCharCodes(codeUnits);
  }

  static List<_CodePointRange> _readCodePointRanges(
    ByteData data,
    _TableRecord table,
  ) {
    final tableOffset = table.offset;
    final count = data.getUint16(tableOffset + 2);
    final subtables = <_CmapSubtable>[];

    for (var i = 0; i < count; i += 1) {
      final recordOffset = tableOffset + 4 + (i * 8);
      subtables.add(
        _CmapSubtable(
          offset: tableOffset + data.getUint32(recordOffset + 4),
        ),
      );
    }

    final format12 = _firstSubtableWithFormat(data, subtables, 12);
    if (format12 != null) {
      return _readFormat12Ranges(data, format12.offset);
    }

    final format4 = _firstSubtableWithFormat(data, subtables, 4);
    if (format4 != null) {
      return _readFormat4Ranges(data, format4.offset);
    }

    fail('BooraIcons.ttf does not expose a supported cmap format.');
  }

  static _CmapSubtable? _firstSubtableWithFormat(
    ByteData data,
    List<_CmapSubtable> subtables,
    int format,
  ) {
    for (final subtable in subtables) {
      if (data.getUint16(subtable.offset) == format) {
        return subtable;
      }
    }
    return null;
  }

  static List<_CodePointRange> _readFormat12Ranges(ByteData data, int offset) {
    final groups = data.getUint32(offset + 12);
    final ranges = <_CodePointRange>[];
    for (var i = 0; i < groups; i += 1) {
      final groupOffset = offset + 16 + (i * 12);
      ranges.add(
        _CodePointRange(
          start: data.getUint32(groupOffset),
          end: data.getUint32(groupOffset + 4),
        ),
      );
    }
    return ranges;
  }

  static List<_CodePointRange> _readFormat4Ranges(ByteData data, int offset) {
    final segmentCount = data.getUint16(offset + 6) ~/ 2;
    final endCodeOffset = offset + 14;
    final startCodeOffset = endCodeOffset + (segmentCount * 2) + 2;
    final ranges = <_CodePointRange>[];

    for (var i = 0; i < segmentCount; i += 1) {
      final end = data.getUint16(endCodeOffset + (i * 2));
      final start = data.getUint16(startCodeOffset + (i * 2));
      if (start != 0xffff && end != 0xffff) {
        ranges.add(_CodePointRange(start: start, end: end));
      }
    }
    return ranges;
  }
}

class _TableRecord {
  const _TableRecord({
    required this.offset,
  });

  final int offset;
}

class _CmapSubtable {
  const _CmapSubtable({
    required this.offset,
  });

  final int offset;
}

class _CodePointRange {
  const _CodePointRange({
    required this.start,
    required this.end,
  });

  final int start;
  final int end;

  bool contains(int codePoint) {
    return codePoint >= start && codePoint <= end;
  }
}
