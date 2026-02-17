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
  late Future<Uint8List> _bytesFuture;

  @override
  void initState() {
    super.initState();
    _bytesFuture = widget.file.readAsBytes();
  }

  @override
  void didUpdateWidget(covariant TenantAdminXFilePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path != widget.file.path ||
        oldWidget.file.name != widget.file.name) {
      _bytesFuture = widget.file.readAsBytes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _bytesFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.memory(
            snapshot.data!,
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
      },
    );
  }
}
