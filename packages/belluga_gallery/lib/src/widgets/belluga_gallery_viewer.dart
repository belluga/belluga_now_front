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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surfaceBrightness = ThemeData.estimateBrightnessForColor(
      colorScheme.surface,
    );
    final overlayStyle = surfaceBrightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;
    final selectedItem = _controller.selectedItem!;
    final selectedIndex = _controller.selectedIndex;
    final itemTitle = selectedItem.title?.trim() ?? '';
    final itemDescription = selectedItem.description?.trim() ?? '';
    final hasMetadata = itemTitle.isNotEmpty || itemDescription.isNotEmpty;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: colorScheme.surface,
        systemNavigationBarIconBrightness: surfaceBrightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Material(
        color: colorScheme.surface,
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
                        foregroundColor: colorScheme.onSurface,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                      ),
                      icon: const Icon(Icons.close_rounded),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.galleryTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurface,
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
                            color: colorScheme.surfaceContainerHighest,
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
                              style: TextStyle(
                                color: colorScheme.onSurface,
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
                      color: colorScheme.surfaceContainerLowest,
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
                if (hasMetadata) ...[
                  const SizedBox(height: 16),
                  _itemMetadata(
                    item: selectedItem,
                    title: itemTitle,
                    description: itemDescription,
                    theme: theme,
                  ),
                  const SizedBox(height: 14),
                ] else
                  const SizedBox(height: 12),
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
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.outlineVariant,
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
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.broken_image_outlined, size: 48),
          ),
        ),
      );
    }
    return _youtube(item as GalleryYoutubePlayer);
  }

  Widget _itemMetadata({
    required GalleryItem item,
    required String title,
    required String description,
    required ThemeData theme,
  }) {
    final colorScheme = theme.colorScheme;
    final isVideo = item is GalleryYoutubePlayer;
    return SizedBox(
      key: const Key('bellugaGalleryViewerMetadata'),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                isVideo ? Icons.videocam_outlined : Icons.photo_camera_outlined,
                size: 18,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                isVideo ? 'VÍDEO' : 'FOTO',
                key: const Key('bellugaGalleryViewerItemType'),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          if (title.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              title,
              key: const Key('bellugaGalleryViewerItemTitle'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          if (description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Semantics(
              label: 'Descrição: $description',
              child: ExcludeSemantics(
                child: Text(
                  description,
                  key: const Key('bellugaGalleryViewerDescription'),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _youtube(GalleryYoutubePlayer video) {
    final player = _controller.youtubeController;
    if (_controller.selectedItem == video && player != null) {
      return _fittedMedia(
        aspectRatio: video.playerAspectRatio,
        child: YoutubePlayer(
          key: Key('bellugaGalleryYoutubePlayer_${video.itemId}'),
          controller: player,
          aspectRatio: video.playerAspectRatio,
        ),
      );
    }
    return _fittedMedia(
      aspectRatio: video.playerAspectRatio,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          GalleryItemPreview(
            key: Key('bellugaGalleryViewerYoutubePreview_${video.itemId}'),
            item: video,
            onTap: _controller.playSelected,
          ),
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
    );
  }

  Widget _fittedMedia({required double aspectRatio, required Widget child}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth || !constraints.hasBoundedHeight) {
          return Center(
            child: AspectRatio(aspectRatio: aspectRatio, child: child),
          );
        }
        final widthAtFullHeight = constraints.maxHeight * aspectRatio;
        final usesFullHeight = widthAtFullHeight <= constraints.maxWidth;
        final width = usesFullHeight ? widthAtFullHeight : constraints.maxWidth;
        final height = usesFullHeight
            ? constraints.maxHeight
            : constraints.maxWidth / aspectRatio;
        return Center(
          child: SizedBox(width: width, height: height, child: child),
        );
      },
    );
  }
}
