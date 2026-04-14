import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class TenantAdminFaviconPreview extends StatefulWidget {
  const TenantAdminFaviconPreview({
    super.key,
    this.bytes,
    this.mimeType,
    this.remoteUrl,
  });

  final Uint8List? bytes;
  final String? mimeType;
  final String? remoteUrl;

  @override
  State<TenantAdminFaviconPreview> createState() =>
      _TenantAdminFaviconPreviewState();
}

class _TenantAdminFaviconPreviewState extends State<TenantAdminFaviconPreview> {
  static int _nextViewId = 0;
  static const String _previewSize = '40px';

  late final String _viewType;
  late final web.HTMLDivElement _hostElement;
  late final web.HTMLImageElement _imageElement;

  @override
  void initState() {
    super.initState();
    _viewType = 'tenant-admin-favicon-preview-${_nextViewId++}';
    _hostElement = web.HTMLDivElement()
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.display = 'flex'
      ..style.alignItems = 'center'
      ..style.justifyContent = 'center'
      ..style.overflow = 'hidden';
    _imageElement = web.HTMLImageElement()
      ..style.width = _previewSize
      ..style.height = _previewSize
      ..style.objectFit = 'contain'
      ..style.display = 'block'
      ..draggable = false;
    _hostElement.append(_imageElement);
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (_) => _hostElement,
    );
    _syncSource();
  }

  @override
  void didUpdateWidget(covariant TenantAdminFaviconPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameBytes(oldWidget.bytes, widget.bytes) ||
        oldWidget.mimeType != widget.mimeType ||
        oldWidget.remoteUrl != widget.remoteUrl) {
      _syncSource();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_resolvedSource == null) {
      return Icon(
        Icons.image_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );
    }

    return HtmlElementView(viewType: _viewType);
  }

  String? get _resolvedSource {
    final bytes = widget.bytes;
    if (bytes != null && bytes.isNotEmpty) {
      final mimeType = widget.mimeType?.trim().isNotEmpty == true
          ? widget.mimeType!.trim()
          : 'image/x-icon';
      return 'data:$mimeType;base64,${base64Encode(bytes)}';
    }

    final normalizedRemoteUrl = widget.remoteUrl?.trim();
    if (normalizedRemoteUrl == null || normalizedRemoteUrl.isEmpty) {
      return null;
    }

    return normalizedRemoteUrl;
  }

  void _syncSource() {
    _imageElement.src = _resolvedSource ?? '';
  }

  bool _sameBytes(Uint8List? previous, Uint8List? current) {
    if (identical(previous, current)) {
      return true;
    }

    if (previous == null || current == null) {
      return previous == current;
    }

    if (previous.lengthInBytes != current.lengthInBytes) {
      return false;
    }

    for (var index = 0; index < previous.lengthInBytes; index++) {
      if (previous[index] != current[index]) {
        return false;
      }
    }

    return true;
  }
}
