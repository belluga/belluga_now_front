import 'package:belluga_now/presentation/tenant/schedule/screens/event_detail_screen/controllers/event_detail_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class AnimatedBooraButton extends StatefulWidget {
  const AnimatedBooraButton({
    super.key,
    required this.isConfirmed,
    required this.onPressed,
    required this.text,
  }) : controller = null;

  @visibleForTesting
  const AnimatedBooraButton.withController(
    this.controller, {
    super.key,
    required this.isConfirmed,
    required this.onPressed,
    required this.text,
  });

  final bool isConfirmed;
  final VoidCallback? onPressed;
  final String text;
  final EventDetailController? controller;

  @override
  State<AnimatedBooraButton> createState() => _AnimatedBooraButtonState();
}

class _AnimatedBooraButtonState extends State<AnimatedBooraButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  EventDetailController get _controller =>
      widget.controller ?? GetIt.I.get<EventDetailController>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Stop animation if confirmed
    if (widget.isConfirmed) {
      _animationController.stop();
      _animationController.value = 0; // Reset to original scale
    } else if (!_animationController.isAnimating) {
      _animationController.repeat(reverse: true);
    }

    return StreamValueBuilder<bool>(
      streamValue: _controller.isLoadingStreamValue,
      builder: (context, isLoading) {
        return AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.isConfirmed ? 1.0 : _scaleAnimation.value,
              child: child,
            );
          },
          child: Container(
            decoration: widget.isConfirmed
                ? null
                : BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
            child: FilledButton(
              onPressed: isLoading ? null : widget.onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: widget.isConfirmed
                    ? colorScheme.surfaceContainerHighest
                    : colorScheme.primary,
                foregroundColor: widget.isConfirmed
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  );
                },
                child: isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          key: const ValueKey<String>('loading'),
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            widget.isConfirmed
                                ? colorScheme.onSurfaceVariant
                                : colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : Text(
                        widget.text,
                        key: ValueKey<String>(widget.text),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
