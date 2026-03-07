import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class TenantAdminXFilePreview extends StatefulWidget {
  const TenantAdminXFilePreview({
    super.key,
    required this.file,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
  });

  final XFile file;
  final double width;
  final double height;
  final BoxFit fit;

  @override
  State<TenantAdminXFilePreview> createState() =>
      _TenantAdminXFilePreviewState();
}

class _TenantAdminXFilePreviewState extends State<TenantAdminXFilePreview> {
  Uint8List? _bytes;
  int _loadToken = 0;

  @override
  void initState() {
    super.initState();
    _loadBytes();
  }

  @override
  void didUpdateWidget(covariant TenantAdminXFilePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path != widget.file.path ||
        oldWidget.file.name != widget.file.name) {
      _loadBytes();
    }
  }

  Future<void> _loadBytes() async {
    final token = ++_loadToken;
    try {
      final bytes = await widget.file.readAsBytes();
      if (!mounted || token != _loadToken) {
        return;
      }
      _bytes = bytes;
      (context as Element).markNeedsBuild();
    } catch (_) {
      if (!mounted || token != _loadToken) {
        return;
      }
      _bytes = null;
      (context as Element).markNeedsBuild();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    if (bytes != null) {
      return Image.memory(
        bytes,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
      );
    }
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: const Icon(Icons.image_outlined),
    );
  }
}
