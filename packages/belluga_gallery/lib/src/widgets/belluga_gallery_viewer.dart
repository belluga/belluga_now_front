import 'dart:async';

import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../gallery_item.dart';
import '../gallery_photo.dart';
import '../gallery_youtube_player.dart';
import '../playback/gallery_viewer_controller.dart';
import 'gallery_item_preview.dart';

final class BellugaGalleryViewer extends StatefulWidget {
  const BellugaGalleryViewer({
    required this.items,
    this.initialIndex = 0,
    this.onClose,
    super.key,
  });

  final List<GalleryItem> items;
  final int initialIndex;
  final VoidCallback? onClose;

  @override
  State<BellugaGalleryViewer> createState() => _BellugaGalleryViewerState();
}

final class _BellugaGalleryViewerState extends State<BellugaGalleryViewer> {
  late final GalleryViewerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GalleryViewerController(
      items: widget.items,
      initialIndex: widget.initialIndex,
    )..addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _controller
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }
    final selectedItem = _controller.selectedItem!;
    return Material(
      color: Colors.black,
      child: SafeArea(
        child: Stack(
          children: <Widget>[
            PageView.builder(
              controller: _controller.pageController,
              itemCount: widget.items.length,
              onPageChanged: (index) =>
                  unawaited(_controller.selectIndex(index)),
              itemBuilder: (context, index) => _viewerItem(widget.items[index]),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton.filledTonal(
                key: const Key('bellugaGalleryViewerClose'),
                tooltip: 'Fechar galeria',
                onPressed: () {
                  unawaited(_controller.closePlayer(reason: 'viewer_closed'));
                  widget.onClose?.call();
                },
                icon: const Icon(Icons.close),
              ),
            ),
            Positioned(
              left: 16,
              bottom: 16,
              child: Semantics(
                label:
                    'Item ${_controller.selectedIndex + 1} de ${widget.items.length}',
                child: ExcludeSemantics(
                  child: Text(
                    '${_controller.selectedIndex + 1}/${widget.items.length}',
                    key: const Key('bellugaGalleryViewerPosition'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            if (selectedItem.description?.trim().isNotEmpty == true)
              Positioned(
                left: 72,
                right: 16,
                bottom: 16,
                child: Semantics(
                  label: 'Descrição: ${selectedItem.description!.trim()}',
                  child: ExcludeSemantics(
                    child: Text(
                      selectedItem.description!.trim(),
                      key: const Key('bellugaGalleryViewerDescription'),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _viewerItem(GalleryItem item) {
    if (item is GalleryPhoto) {
      return InteractiveViewer(
        child: Center(
          child: Image.network(
            item.viewerUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.broken_image_outlined,
              color: Colors.white,
              size: 48,
            ),
          ),
        ),
      );
    }
    return _youtube(item as GalleryYoutubePlayer);
  }

  Widget _youtube(GalleryYoutubePlayer video) {
    final player = _controller.youtubeController;
    if (_controller.selectedItem == video && player != null) {
      return Center(child: YoutubePlayer(controller: player));
    }
    return Center(
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            GalleryItemPreview(item: video, onTap: _controller.playSelected),
            if (_controller.isActivating)
              const Center(child: CircularProgressIndicator())
            else if (_controller.playbackFailed)
              Center(
                child: FilledButton.icon(
                  key: const Key('bellugaGalleryYoutubeRetry'),
                  onPressed: _controller.playSelected,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
