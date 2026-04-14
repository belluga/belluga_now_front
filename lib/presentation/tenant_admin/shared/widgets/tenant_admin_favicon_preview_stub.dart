import 'dart:typed_data';

import 'package:flutter/material.dart';

class TenantAdminFaviconPreview extends StatelessWidget {
  const TenantAdminFaviconPreview({
    super.key,
    this.bytes,
    this.mimeType,
    this.remoteUrl,
  });

  final Uint8List? bytes;
  final String? mimeType;
  final String? remoteUrl;

  static const double _previewSize = 40;

  @override
  Widget build(BuildContext context) {
    final placeholderColor = Theme.of(context).colorScheme.onSurfaceVariant;

    if (bytes != null) {
      return Image.memory(
        bytes!,
        width: _previewSize,
        height: _previewSize,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => Icon(
          Icons.broken_image_outlined,
          color: placeholderColor,
        ),
      );
    }

    final normalizedRemoteUrl = remoteUrl?.trim();
    if (normalizedRemoteUrl != null && normalizedRemoteUrl.isNotEmpty) {
      return Image.network(
        normalizedRemoteUrl,
        width: _previewSize,
        height: _previewSize,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => Icon(
          Icons.broken_image_outlined,
          color: placeholderColor,
        ),
      );
    }

    return Icon(
      Icons.image_outlined,
      color: placeholderColor,
    );
  }
}
