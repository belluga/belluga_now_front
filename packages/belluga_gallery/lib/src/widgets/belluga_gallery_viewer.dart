import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late final List<GlobalKey> _thumbnailKeys;
  int _lastVisibleThumbnail = -1;

  @override
  void initState() {
    super.initState();
    _controller = GalleryViewerController(
      items: widget.items,
      initialIndex: widget.initialIndex,
    )..addListener(_refresh);
    _thumbnailKeys = List<GlobalKey>.generate(
      widget.items.length,
      (index) => GlobalKey(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureSelectedThumbnailVisible();
    });
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {});
    if (_lastVisibleThumbnail != _controller.selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ensureSelectedThumbnailVisible();
      });
    }
  }

  void _ensureSelectedThumbnailVisible() {
    if (!mounted || _thumbnailKeys.isEmpty) return;
    final index = _controller.selectedIndex;
    final thumbnailContext = _thumbnailKeys[index].currentContext;
    if (thumbnailContext == null) return;
    _lastVisibleThumbnail = index;
    unawaited(
      Scrollable.ensureVisible(
        thumbnailContext,
        alignment: 0.5,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      ),
    );
  }

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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Material(
        color: const Color(0xFF0D0D0D),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
                  height: 44,
                  child: selectedItem.description?.trim().isNotEmpty == true
                      ? Semantics(
                          label:
                              'Descrição: ${selectedItem.description!.trim()}',
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
                const SizedBox(height: 10),
                SizedBox(
                  key: const Key('bellugaGalleryViewerSlideRow'),
                  height: 76,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final isSelected = index == selectedIndex;
                      return Semantics(
                        button: true,
                        selected: isSelected,
                        excludeSemantics: true,
                        label:
                            'Selecionar item ${index + 1} de ${widget.items.length}',
                        child: AnimatedContainer(
                          key: _thumbnailKeys[index],
                          duration: const Duration(milliseconds: 180),
                          width: 96,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.white24,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: GalleryItemPreview(
                            key: Key(
                              'bellugaGalleryViewerThumbnail_${widget.items[index].itemId}',
                            ),
                            item: widget.items[index],
                            onTap: () => unawaited(
                              _controller.pageController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 240),
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
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
            key: Key('bellugaGalleryViewerPhoto_${item.itemId}'),
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
