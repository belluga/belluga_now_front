import 'package:flutter/material.dart';

class SwipeableCard extends StatefulWidget {
  const SwipeableCard({
    super.key,
    required this.child,
    this.backgroundChild,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onSwipeUp,
    this.onSwipeDown,
    this.enableRotation = true,
    this.rotationFactor = 0.001, // Adjusted for sensible rotation
    this.swipeThreshold = 100.0,
    this.velocityThreshold = 1000.0,
  });

  final Widget child;
  final Widget? backgroundChild;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeUp;
  final VoidCallback? onSwipeDown;
  final bool enableRotation;
  final double rotationFactor;
  final double swipeThreshold;
  final double velocityThreshold;

  @override
  State<SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<SwipeableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  bool _isAnimatingOut = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
        .animate(_controller);

    _controller.addListener(() {
      setState(() {
        if (!_isDragging) {
          _dragOffset = _animation.value;
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (_isAnimatingOut) return;
    _isDragging = true;
    _controller.stop();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isAnimatingOut) return;
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isAnimatingOut) return;
    _isDragging = false;

    final velocity = details.velocity.pixelsPerSecond;
    final dx = _dragOffset.dx;
    final dy = _dragOffset.dy;
    final absDx = dx.abs();
    final absDy = dy.abs();

    // Determine primary direction
    bool isHorizontal = absDx > absDy;

    if (isHorizontal) {
      if (dx > widget.swipeThreshold ||
          (dx > 0 && velocity.dx > widget.velocityThreshold)) {
        // Swipe Right
        if (widget.onSwipeRight != null) {
          _animateOut(const Offset(500, 0), widget.onSwipeRight!);
        } else {
          _snapBack();
        }
      } else if (dx < -widget.swipeThreshold ||
          (dx < 0 && velocity.dx < -widget.velocityThreshold)) {
        // Swipe Left
        if (widget.onSwipeLeft != null) {
          _animateOut(const Offset(-500, 0), widget.onSwipeLeft!);
        } else {
          _snapBack();
        }
      } else {
        _snapBack();
      }
    } else {
      if (dy > widget.swipeThreshold ||
          (dy > 0 && velocity.dy > widget.velocityThreshold)) {
        // Swipe Down
        if (widget.onSwipeDown != null) {
          _animateOut(const Offset(0, 500), widget.onSwipeDown!);
        } else {
          _snapBack();
        }
      } else if (dy < -widget.swipeThreshold ||
          (dy < 0 && velocity.dy < -widget.velocityThreshold)) {
        // Swipe Up
        if (widget.onSwipeUp != null) {
          _animateOut(const Offset(0, -500), widget.onSwipeUp!);
        } else {
          _snapBack();
        }
      } else {
        _snapBack();
      }
    }
  }

  void _snapBack() {
    _animation = Tween<Offset>(begin: _dragOffset, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward(from: 0);
  }

  void _animateOut(Offset target, VoidCallback onComplete) {
    _isAnimatingOut = true;
    _animation = Tween<Offset>(begin: _dragOffset, end: target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward(from: 0).then((_) {
      onComplete();
      // Reset state for reuse if the widget isn't disposed (e.g. in a stack)
      if (mounted) {
        // Ideally the parent removes this widget, but if not, we reset.
        // For a stack, the parent rebuilds with new content.
        // We can reset _isAnimatingOut here just in case.
        _isAnimatingOut = false;
        _dragOffset = Offset.zero;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final angle =
        widget.enableRotation ? _dragOffset.dx * widget.rotationFactor : 0.0;

    return Stack(
      children: [
        if (widget.backgroundChild != null)
          Positioned.fill(child: widget.backgroundChild!),
        GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: Transform.translate(
            offset: _dragOffset,
            child: Transform.rotate(
              angle: angle,
              child: widget.child,
            ),
          ),
        ),
      ],
    );
  }
}
