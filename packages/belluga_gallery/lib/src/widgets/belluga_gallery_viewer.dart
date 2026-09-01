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
    this.galleryTitle = 'Galeria',
    this.initialIndex = 0,
    this.onClose,
    super.key,
  });

  final List<GalleryItem> items;
  final String galleryTitle;
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
    final selectedIndex = _controller.selectedIndex;
    return Material(
      color: const Color(0xFF121212),
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: <Widget>[
              Row(
                children: [
                  IconButton(
                    key: const Key('bellugaGalleryViewerClose'),
                    tooltip: 'Fechar galeria',
                    onPressed: () {
                      unawaited(
                        _controller.closePlayer(reason: 'viewer_closed'),
                      );
                      widget.onClose?.call();
                    },
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFF2B2B2B),
                    ),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.galleryTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Semantics(
                    label:
                        'Item ${selectedIndex + 1} de ${widget.items.length}',
                    child: ExcludeSemantics(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2B2B2B),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          child: Text(
                            '${selectedIndex + 1}/${widget.items.length}',
                            key: const Key('bellugaGalleryViewerPosition'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: ColoredBox(
                    color: Colors.black,
                    child: PageView.builder(
                      controller: _controller.pageController,
                      itemCount: widget.items.length,
                      onPageChanged: (index) =>
                          unawaited(_controller.selectIndex(index)),
                      itemBuilder: (context, index) =>
                          _viewerItem(widget.items[index]),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: selectedItem.description?.trim().isNotEmpty == true
                    ? Semantics(
                        label: 'Descrição: ${selectedItem.description!.trim()}',
                        child: ExcludeSemantics(
                          child: Text(
                            selectedItem.description!.trim(),
                            key: const Key('bellugaGalleryViewerDescription'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFE6E6E6),
                              fontSize: 16,
                              height: 1.35,
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('bellugaGalleryViewerPrevious'),
                      onPressed: selectedIndex == 0
                          ? null
                          : () => unawaited(
                              _controller.pageController.previousPage(
                                duration: const Duration(milliseconds: 240),
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                      icon: const Icon(Icons.chevron_left_rounded),
                      label: const Text('Anterior'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white38,
                        side: BorderSide(
                          color: selectedIndex == 0
                              ? Colors.white24
                              : Colors.white54,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      key: const Key('bellugaGalleryViewerNext'),
                      onPressed: selectedIndex == widget.items.length - 1
                          ? null
                          : () => unawaited(
                              _controller.pageController.nextPage(
                                duration: const Duration(milliseconds: 240),
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                      iconAlignment: IconAlignment.end,
                      icon: const Icon(Icons.chevron_right_rounded),
                      label: const Text('Próximo'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: Colors.white12,
                        disabledForegroundColor: Colors.white38,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
