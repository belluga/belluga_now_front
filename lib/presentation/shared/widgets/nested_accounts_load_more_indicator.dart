import 'dart:async';

import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

class NestedAccountsLoadMoreIndicator extends StatelessWidget {
  const NestedAccountsLoadMoreIndicator({
    required this.visibilityKey,
    required this.hasMore,
    required this.isLoading,
    required this.onLoadMore,
    this.loadingLabel = 'Carregando mais perfis...',
    super.key,
  });

  final String visibilityKey;
  final bool hasMore;
  final bool isLoading;
  final Future<void> Function() onLoadMore;
  final String loadingLabel;

  @override
  Widget build(BuildContext context) {
    if (!hasMore && !isLoading) {
      return const SizedBox.shrink();
    }

    return VisibilityDetector(
      key: Key(visibilityKey),
      onVisibilityChanged: (info) {
        if (!hasMore || isLoading || info.visibleFraction <= 0) {
          return;
        }
        unawaited(onLoadMore());
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: SizedBox(
          height: 32,
          child: Center(
            child: isLoading
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(loadingLabel),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
