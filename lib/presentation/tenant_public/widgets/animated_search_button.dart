import 'dart:async';
import 'package:flutter/material.dart';

class AnimatedSearchButton extends StatefulWidget {
  const AnimatedSearchButton({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  State<AnimatedSearchButton> createState() => _AnimatedSearchButtonState();
}

class _AnimatedSearchButtonState extends State<AnimatedSearchButton> {
  // Static variable to track if this is the first time in the session
  static bool _isFirstSessionVisit = true;

  late bool _isExpanded;
  late bool _showText;
  Timer? _shrinkTimer;

  @override
  void initState() {
    super.initState();
    _isExpanded = _isFirstSessionVisit;
    _showText = _isFirstSessionVisit;

    if (_isFirstSessionVisit) {
      // Mark as visited so next time it doesn't expand
      _isFirstSessionVisit = false;
      _scheduleShrink();
    }
  }

  @override
  void dispose() {
    _shrinkTimer?.cancel();
    super.dispose();
  }

  void _scheduleShrink() {
    _shrinkTimer?.cancel();
    _shrinkTimer = Timer(const Duration(seconds: 5), () {
      setState(() {
        _showText = false;
        _isExpanded = false;
      });
    });
  }

  void _handleTap() {
    if (!_isExpanded) {
      setState(() {
        _isExpanded = true;
        // Text will be shown in onEnd callback
      });
      _scheduleShrink();
    } else {
      _shrinkTimer?.cancel();
      // Shrink immediately so it's closed when the user returns
      setState(() {
        _showText = false;
        _isExpanded = false;
      });
      widget.onTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
        onEnd: () {
          if (_isExpanded) {
            setState(() {
              _showText = true;
            });
          }
        },
        height: 48,
        width: _isExpanded ? 280 : 48,
        decoration: ShapeDecoration(
          color: _isExpanded
              ? colorScheme.surfaceContainerHighest
              : Colors.transparent,
          shape: const StadiumBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Icon(
                Icons.search,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (_showText) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'O que você quer fazer hoje?',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
            ],
          ],
        ),
      ),
    );
  }
}
