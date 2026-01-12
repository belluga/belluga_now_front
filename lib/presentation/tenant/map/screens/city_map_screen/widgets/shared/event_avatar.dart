import 'package:flutter/material.dart';

import 'avatar_fallback.dart';

class EventAvatar extends StatelessWidget {
  const EventAvatar({
    super.key,
    required this.imageUrl,
    required this.fallbackColor,
    required this.isPast,
  });

  final String? imageUrl;
  final Color fallbackColor;
  final bool isPast;

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  AvatarFallback(color: fallbackColor),
            )
          : AvatarFallback(color: fallbackColor),
    );

    if (!isPast) {
      return avatar;
    }

    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]),
      child: Opacity(opacity: 0.4, child: avatar),
    );
  }
}
