import 'dart:convert';

class SafeRichHtml {
  const SafeRichHtml._();

  static String canonicalize(
    String raw, {
    bool allowExplicitHttpsLinks = false,
  }) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final html = looksLikeHtml(trimmed)
        ? _canonicalizeMarkup(trimmed, allowExplicitHttpsLinks)
        : _wrapPlainText(trimmed);
    return isEffectivelyEmpty(html) ? '' : html;
  }

  static bool looksLikeHtml(String value) =>
      RegExp(r'</[a-zA-Z][a-zA-Z0-9:-]*\s*>').hasMatch(value) ||
      RegExp(r'<[a-zA-Z][a-zA-Z0-9:-]*(?:\s[^>]*)?/>').hasMatch(value) ||
      RegExp(
        r'</?(?:a|b|blockquote|body|br|div|em|h[1-6]|html|iframe|img|li|ol|p|s|script|span|strong|style|table|tbody|td|tfoot|th|thead|tr|u|ul)(?:\s[^>]*)?/?>',
        caseSensitive: false,
      ).hasMatch(value);

  static bool isEffectivelyEmpty(String html) {
    final compact = html
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('\u00a0', ' ')
        .trim();
    return compact.isEmpty;
  }

  static bool isAllowedExplicitHttpsHref(String raw) {
    if (raw.isEmpty || raw != raw.trim()) {
      return false;
    }
    if (RegExp(r'''[\x00-\x20\x7f\\"<>{}']''').hasMatch(raw) ||
        RegExp(r'%(?![0-9A-Fa-f]{2})').hasMatch(raw) ||
        RegExp(r'%(?:0[0-9A-Fa-f]|1[0-9A-Fa-f]|20|7[fF])').hasMatch(raw)) {
      return false;
    }

    final absolute = RegExp(
      r'^https://([^/?#]+)(?:[/?#].*)?$',
      caseSensitive: false,
    ).firstMatch(raw);
    if (absolute == null) return false;

    final authority = absolute.group(1)!;
    if (authority.contains('@') || authority.contains('%')) return false;
    final bracketedIpv6 = authority.startsWith('[');
    final authorityMatch = bracketedIpv6
        ? RegExp(r'^\[([0-9A-Fa-f:.]+)\](?::([0-9]+))?$').firstMatch(authority)
        : RegExp(r'^([^:]+)(?::([0-9]+))?$').firstMatch(authority);
    if (authorityMatch == null) return false;
    final lexicalHost = authorityMatch.group(1)!;
    final port = authorityMatch.group(2);
    if (port != null) {
      if (port.length > 1 && port.startsWith('0')) return false;
      final parsedPort = int.tryParse(port);
      if (parsedPort == null || parsedPort < 1 || parsedPort > 65535) {
        return false;
      }
    }

    try {
      final uri = Uri.parse(raw);
      return uri.scheme.toLowerCase() == 'https' &&
          uri.hasAuthority &&
          uri.host.isNotEmpty &&
          uri.host.toLowerCase() == lexicalHost.toLowerCase() &&
          (port == null || uri.port == int.parse(port)) &&
          uri.userInfo.isEmpty;
    } on FormatException {
      return false;
    }
  }

  static String? canonicalExplicitHttpsHref(String raw) {
    if (!isAllowedExplicitHttpsHref(raw)) return null;
    return 'https${raw.substring(raw.indexOf(':'))}';
  }

  static Uri? canonicalExplicitHttpsUri(String raw) {
    final decoded = _decodeCanonicalAmpEntities(raw);
    if (decoded == null) return null;
    final href = canonicalExplicitHttpsHref(decoded);
    if (href == null) return null;
    try {
      return Uri.parse(href);
    } on FormatException {
      return null;
    }
  }

  static String sanitizeMarkupFragment(
    String html, {
    bool allowExplicitHttpsLinks = false,
  }) {
    return _sanitizeMarkup(html, allowExplicitHttpsLinks);
  }

  static String _canonicalizeMarkup(String html, bool allowExplicitHttpsLinks) {
    final sanitized = _sanitizeMarkup(html, allowExplicitHttpsLinks).trim();
    if (sanitized.isEmpty) {
      return '';
    }
    if (_containsBlockTag(sanitized)) {
      return sanitized;
    }
    return '<p>$sanitized</p>';
  }

  static String _wrapPlainText(String value) {
    final normalized = value
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .trim();
    if (normalized.isEmpty) {
      return '';
    }

    final paragraphs = normalized
        .split(RegExp(r'\n\s*\n+'))
        .map((paragraph) {
          final lines = paragraph
              .split('\n')
              .map((line) => htmlEscape.convert(line.trimRight()))
              .toList(growable: false);
          return '<p>${lines.join('<br />')}</p>';
        })
        .where((paragraph) => !isEffectivelyEmpty(paragraph))
        .toList(growable: false);

    return paragraphs.join();
  }

  static String _sanitizeMarkup(String html, bool allowExplicitHttpsLinks) {
    html = _preflightAnchors(html, allowExplicitHttpsLinks);
    final acceptedAnchorStack = <bool>[];
    var sanitized = html
        .replaceAll(RegExp(r'<!--[\s\S]*?-->'), '')
        .replaceAll(
          RegExp(r'<script\b[^>]*>[\s\S]*?<\/script>', caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(r'<style\b[^>]*>[\s\S]*?<\/style>', caseSensitive: false),
          '',
        );

    sanitized = sanitized.replaceAllMapped(
      RegExp(r'</?([a-zA-Z][a-zA-Z0-9:-]*)(?:\s[^>]*)?\/?>'),
      (match) {
        final rawTag = match.group(1)?.toLowerCase() ?? '';
        final rawMatch = match.group(0) ?? '';
        final isClosing = rawMatch.startsWith('</');

        if (rawTag == 'br') {
          return '<br />';
        }
        if (rawTag == 'a') {
          if (isClosing) {
            if (acceptedAnchorStack.isEmpty) return '';
            return acceptedAnchorStack.removeLast() ? '</a>' : '';
          }
          if (rawMatch.endsWith('/>')) return '';
          final href = RegExp(
            r'''^<a\s+href\s*=\s*(?:"([^"]+)"|'([^']+)')\s*>$''',
            caseSensitive: false,
          ).firstMatch(rawMatch);
          final rawHref = href?.group(1) ?? href?.group(2);
          final decodedHref = rawHref == null
              ? null
              : _decodeCanonicalAmpEntities(rawHref);
          final accepted =
              allowExplicitHttpsLinks &&
              decodedHref != null &&
              isAllowedExplicitHttpsHref(decodedHref);
          acceptedAnchorStack.add(accepted);
          if (!accepted) return '';
          return '<a href="${_canonicalHrefAttribute(decodedHref)}">';
        }

        if (!_allowedTags.contains(rawTag)) {
          return '';
        }

        if (isClosing) {
          return '</$rawTag>';
        }

        return '<$rawTag>';
      },
    );

    return sanitized;
  }

  static String _preflightAnchors(String html, bool allowExplicitHttpsLinks) {
    final tags = _scanMarkupTags(html);
    final (closingByOpening, anchorOpeningPrefix) = _pairAnchorTags(tags);
    final output = StringBuffer();
    var cursor = 0;
    var index = 0;
    while (index < tags.length) {
      final tag = tags[index];
      if (tag.name != 'a') {
        index++;
        continue;
      }
      output.write(html.substring(cursor, tag.start));
      if (tag.closing) {
        cursor = tag.end;
        index++;
        continue;
      }
      final closingIndex = closingByOpening[index];
      if (closingIndex == null) {
        cursor = tag.end;
        index++;
        continue;
      }
      final closing = tags[closingIndex];
      final ambiguous =
          anchorOpeningPrefix[closingIndex] > anchorOpeningPrefix[index];
      var contents = html.substring(tag.end, closing.start);
      if (ambiguous) contents = _removeScannedAnchorTags(contents);
      final grammar = RegExp(
        r'''^<a[ \t]+href[ \t]*=[ \t]*(?:"([^"]*)"|'([^']*)')[ \t]*>$''',
        caseSensitive: false,
      ).firstMatch(tag.raw);
      final encodedHref = grammar?.group(1) ?? grammar?.group(2);
      final href = encodedHref == null
          ? null
          : _decodeCanonicalAmpEntities(encodedHref);
      final accepted =
          allowExplicitHttpsLinks &&
          !ambiguous &&
          !_hasRejectedNestedAnchorMarkup(contents) &&
          href != null &&
          isAllowedExplicitHttpsHref(href);
      if (accepted) {
        output
          ..write('<a href="${_canonicalHrefAttribute(href)}">')
          ..write(contents)
          ..write('</a>');
      } else {
        output.write(contents);
      }
      cursor = closing.end;
      index = closingIndex + 1;
    }
    output.write(html.substring(cursor));
    return output.toString();
  }

  static (Map<int, int>, List<int>) _pairAnchorTags(
    List<({int start, int end, String raw, String name, bool closing})> tags,
  ) {
    final openingStack = <int>[];
    final closingByOpening = <int, int>{};
    final anchorOpeningPrefix = List<int>.filled(tags.length, 0);
    var openingCount = 0;

    for (var index = 0; index < tags.length; index++) {
      final tag = tags[index];
      if (tag.name == 'a' && !tag.closing) {
        openingStack.add(index);
        openingCount++;
      } else if (tag.name == 'a' &&
          tag.raw.toLowerCase() == '</a>' &&
          openingStack.isNotEmpty) {
        closingByOpening[openingStack.removeLast()] = index;
      }
      anchorOpeningPrefix[index] = openingCount;
    }

    return (closingByOpening, anchorOpeningPrefix);
  }

  static List<({int start, int end, String raw, String name, bool closing})>
  _scanMarkupTags(String html) {
    final tags =
        <({int start, int end, String raw, String name, bool closing})>[];
    var cursor = 0;
    while (cursor < html.length) {
      final start = html.indexOf('<', cursor);
      if (start < 0) break;
      var position = start + 1;
      while (position < html.length &&
          _isTagWhitespace(html.codeUnitAt(position))) {
        position++;
      }
      var closing = false;
      if (position < html.length && html[position] == '/') {
        closing = true;
        position++;
        while (position < html.length &&
            _isTagWhitespace(html.codeUnitAt(position))) {
          position++;
        }
      }
      final nameStart = position;
      while (position < html.length &&
          _isTagNameCodeUnit(html.codeUnitAt(position))) {
        position++;
      }
      if (position == nameStart) {
        cursor = start + 1;
        continue;
      }
      final name = html.substring(nameStart, position).toLowerCase();
      String? quote;
      var end = -1;
      var malformedAnchorEnd = -1;
      for (var probe = position; probe < html.length; probe++) {
        final character = html[probe];
        if (quote == null && (character == '"' || character == "'")) {
          quote = character;
        } else if (quote == character) {
          quote = null;
        } else if (quote == null && character == '>') {
          end = probe + 1;
          break;
        } else if (character == '>' && malformedAnchorEnd < 0) {
          malformedAnchorEnd = probe + 1;
        }
      }
      if (end < 0 && name == 'a') {
        end = malformedAnchorEnd;
      }
      if (end < 0) {
        // An unterminated quoted tag owns the remaining source under the
        // quote-aware grammar. Stopping here is both fail-closed and avoids
        // rescanning the same suffix for every nested `<a` candidate.
        if (name == 'a') {
          tags.add((
            start: start,
            end: html.length,
            raw: html.substring(start),
            name: name,
            closing: closing,
          ));
        }
        break;
      }
      tags.add((
        start: start,
        end: end,
        raw: html.substring(start, end),
        name: name,
        closing: closing,
      ));
      cursor = end;
    }
    return tags;
  }

  static String _removeScannedAnchorTags(String value) {
    final output = StringBuffer();
    var cursor = 0;
    for (final tag in _scanMarkupTags(value)) {
      if (tag.name != 'a') continue;
      output.write(value.substring(cursor, tag.start));
      cursor = tag.end;
    }
    output.write(value.substring(cursor));
    return output.toString();
  }

  static bool _isTagWhitespace(int codeUnit) =>
      codeUnit == 0x09 ||
      codeUnit == 0x0A ||
      codeUnit == 0x0D ||
      codeUnit == 0x20;

  static bool _isTagNameCodeUnit(int codeUnit) =>
      (codeUnit >= 0x30 && codeUnit <= 0x39) ||
      (codeUnit >= 0x41 && codeUnit <= 0x5A) ||
      (codeUnit >= 0x61 && codeUnit <= 0x7A) ||
      codeUnit == 0x3A ||
      codeUnit == 0x2D;

  static bool _hasRejectedNestedAnchorMarkup(String contents) {
    final tags = RegExp(
      r'<\s*/?\s*([a-zA-Z][a-zA-Z0-9:-]*)\b[^>]*>',
    ).allMatches(contents);
    for (final tag in tags) {
      final name = tag.group(1)!.toLowerCase();
      if (name == 'a' || (name != 'br' && !_allowedTags.contains(name))) {
        return true;
      }
    }
    return false;
  }

  static String? _decodeCanonicalAmpEntities(String value) {
    final entities = RegExp(r'&(?:#[^;\s<>&]*|[A-Za-z][A-Za-z0-9]*);');
    for (final entity in entities.allMatches(value)) {
      if (entity.group(0) != '&amp;') return null;
    }
    final decoded = value.replaceAll('&amp;', '&');
    if (entities.hasMatch(decoded)) return null;
    return decoded;
  }

  static String _canonicalHrefAttribute(String href) {
    final canonical = canonicalExplicitHttpsHref(href)!;
    return canonical
        .replaceAll('&', '&amp;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }

  static bool _containsBlockTag(String value) {
    return RegExp(
      r'<(blockquote|h[1-6]|li|ol|p|ul)\b',
      caseSensitive: false,
    ).hasMatch(value);
  }

  static const Set<String> _allowedTags = {
    'blockquote',
    'br',
    'em',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
    'li',
    'ol',
    'p',
    's',
    'strong',
    'ul',
  };
}
