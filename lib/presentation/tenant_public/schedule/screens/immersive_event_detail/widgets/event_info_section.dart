import 'dart:convert';

import 'package:belluga_now/application/invites/invite_from_event_factory.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class EventInfoSection extends StatelessWidget {
  const EventInfoSection({
    required this.event,
    super.key,
  });

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final html = _canonicalizeHtml(event.content.value?.trim() ?? '');
    if (InviteFromEventFactory.stripHtml(html).isEmpty) {
      return const SizedBox.shrink();
    }
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16).copyWith(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sobre',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Html(
            data: html,
            style: {
              'body': Style(
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
                color: colorScheme.onSurfaceVariant,
                fontSize: FontSize(
                  Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16,
                ),
                lineHeight: const LineHeight(1.45),
              ),
              'p': Style(
                margin: Margins.only(bottom: 12),
              ),
              'strong': Style(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
              'br': Style(
                display: Display.block,
              ),
            },
          ),
        ],
      ),
    );
  }

  String _canonicalizeHtml(String html) {
    final trimmed = html.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final canonicalHtml = _sanitizeHtml(trimmed);
    if (canonicalHtml.isEmpty || _isBlankHtml(canonicalHtml)) {
      return '';
    }

    return canonicalHtml;
  }

  bool _isBlankHtml(String html) {
    final compact = html
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('\u00a0', ' ')
        .trim();
    return compact.isEmpty;
  }

  String _sanitizeHtml(String html) {
    if (!looksLikeHtml(html)) {
      return _wrapPlainText(html);
    }

    final sanitized = _sanitizeMarkup(html);
    final normalized = sanitized.trim();
    if (normalized.isEmpty) {
      return '';
    }

    if (_containsBlockTag(normalized)) {
      return normalized;
    }

    return '<p>$normalized</p>';
  }

  String _wrapPlainText(String value) {
    final normalized =
        value.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
    if (normalized.isEmpty) {
      return '';
    }

    final lines = normalized
        .split('\n')
        .map((line) => htmlEscape.convert(line))
        .toList(growable: false);
    return '<p>${lines.join('<br />')}</p>';
  }

  bool looksLikeHtml(String value) {
    return RegExp(r'<[^>]+>').hasMatch(value);
  }

  String _sanitizeMarkup(String html) {
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
      RegExp(r'</?([a-zA-Z0-9]+)(?:\s[^>]*)?>'),
      (match) {
        final rawTag = match.group(1)?.toLowerCase() ?? '';
        final isClosing = match.group(0)?.startsWith('</') ?? false;

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

  bool _containsBlockTag(String value) {
    return RegExp(r'<(blockquote|h[1-6]|li|ol|p|ul)\b', caseSensitive: false)
        .hasMatch(value);
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
