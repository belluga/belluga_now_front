import 'package:belluga_now/presentation/shared/web/public_page_metadata_payload.dart';
import 'package:web/web.dart' as web;

void applyPublicPageMetadata(PublicPageMetadataPayload payload) {
  final head = web.document.head;
  if (head == null) {
    return;
  }

  final title = payload.title.trim();
  if (title.isNotEmpty) {
    web.document.title = title;
  }

  final description = payload.description.trim();
  _setMetaByName(head, 'description', description);
  _setMetaByProperty(head, 'og:title', title);
  _setMetaByName(head, 'twitter:title', title);
  _setMetaByProperty(head, 'og:description', description);
  _setMetaByName(head, 'twitter:description', description);
  _setMetaByProperty(head, 'og:url', payload.url);
  _setMetaByProperty(head, 'og:type', 'website');
  _setMetaByName(
    head,
    'twitter:card',
    _hasValue(payload.imageUrl) ? 'summary_large_image' : 'summary',
  );

  final normalizedImageUrl = payload.imageUrl?.trim();
  if (_hasValue(normalizedImageUrl)) {
    _setMetaByProperty(head, 'og:image', normalizedImageUrl!);
    _setMetaByName(head, 'twitter:image', normalizedImageUrl);
  } else {
    _removeMetaByProperty(head, 'og:image');
    _removeMetaByName(head, 'twitter:image');
  }

  final canonical = _ensureCanonicalLink(head);
  canonical.href = payload.url;
}

bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;

void _setMetaByName(web.HTMLHeadElement head, String name, String content) {
  final normalized = content.trim();
  if (normalized.isEmpty) {
    _removeMetaByName(head, name);
    return;
  }
  final meta = _ensureMeta(head, selector: 'meta[name="$name"]');
  meta.name = name;
  meta.content = normalized;
}

void _setMetaByProperty(
  web.HTMLHeadElement head,
  String property,
  String content,
) {
  final normalized = content.trim();
  if (normalized.isEmpty) {
    _removeMetaByProperty(head, property);
    return;
  }
  final meta = _ensureMeta(head, selector: 'meta[property="$property"]');
  meta.setAttribute('property', property);
  meta.content = normalized;
}

void _removeMetaByName(web.HTMLHeadElement head, String name) {
  head.querySelector('meta[name="$name"]')?.remove();
}

void _removeMetaByProperty(web.HTMLHeadElement head, String property) {
  head.querySelector('meta[property="$property"]')?.remove();
}

web.HTMLMetaElement _ensureMeta(
  web.HTMLHeadElement head, {
  required String selector,
}) {
  final existing = head.querySelector(selector);
  if (existing != null) {
    return existing as web.HTMLMetaElement;
  }
  final meta = web.HTMLMetaElement();
  head.append(meta);
  return meta;
}

web.HTMLLinkElement _ensureCanonicalLink(web.HTMLHeadElement head) {
  final existing = head.querySelector('link[rel="canonical"]');
  if (existing != null) {
    return existing as web.HTMLLinkElement;
  }
  final link = web.HTMLLinkElement()..rel = 'canonical';
  head.append(link);
  return link;
}
