import 'dart:convert';

class SafeRichHtml {
  const SafeRichHtml._();

  static String canonicalize(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final html = looksLikeHtml(trimmed)
        ? _canonicalizeMarkup(trimmed)
        : _wrapPlainText(trimmed);
    return isEffectivelyEmpty(html) ? '' : html;
  }

  static bool looksLikeHtml(String value) => RegExp(r'<[^>]+>').hasMatch(value);

  static bool isEffectivelyEmpty(String html) {
    final compact = html
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('\u00a0', ' ')
        .trim();
    return compact.isEmpty;
  }

  static String _canonicalizeMarkup(String html) {
    final sanitized = _sanitizeMarkup(html).trim();
    if (sanitized.isEmpty) {
      return '';
    }
    if (_containsBlockTag(sanitized)) {
      return sanitized;
    }
    return '<p>$sanitized</p>';
  }

  static String _wrapPlainText(String value) {
    final normalized =
        value.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
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

  static String _sanitizeMarkup(String html) {
    var sanitized = html
        .replaceAll(RegExp(r'<!--[\s\S]*?-->'), '')
        .replaceAll(
          RegExp(r'<script\b[^>]*>[\s\S]*?<\/script>', caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(r'<style\b[^>]*>[\s\S]*?<\/style>', caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(r'<iframe\b[^>]*>[\s\S]*?<\/iframe>', caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(r'<object\b[^>]*>[\s\S]*?<\/object>', caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(r'<embed\b[^>]*>[\s\S]*?<\/embed>', caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(r'<svg\b[^>]*>[\s\S]*?<\/svg>', caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(r'<audio\b[^>]*>[\s\S]*?<\/audio>', caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(r'<video\b[^>]*>[\s\S]*?<\/video>', caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(r'<picture\b[^>]*>[\s\S]*?<\/picture>', caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(r'<img\b[^>]*\/?>', caseSensitive: false),
          '',
        );

    sanitized = sanitized.replaceAllMapped(
      RegExp(r'</?([a-zA-Z0-9]+)(?:\s[^>]*)?\/?>'),
      (match) {
        final rawTag = match.group(1)?.toLowerCase() ?? '';
        final rawMatch = match.group(0) ?? '';
        final isClosing = rawMatch.startsWith('</');

        if (rawTag == 'br') {
          return '<br />';
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
