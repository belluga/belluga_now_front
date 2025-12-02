import 'package:flutter/material.dart';

class SocialProofWidget extends StatelessWidget {
  const SocialProofWidget({
    required this.friendsCount,
    required this.totalCount,
    this.opacity = 1.0,
    super.key,
  });

  final int friendsCount;
  final int totalCount;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      // padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar stack (showing 3 people) - fixed width to prevent cutoff
          SizedBox(
            width: 88, // Increased from 80 to accommodate full third avatar
            height: 40,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[300],
                    child: const Icon(Icons.person, size: 20),
                  ),
                ),
                Positioned(
                  left: 24,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[400],
                    child: const Icon(Icons.person, size: 20),
                  ),
                ),
                Positioned(
                  left: 48,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[500],
                    child: const Icon(Icons.person, size: 20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Text
          Expanded(
            child: Opacity(
              opacity: opacity,
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  children: [
                    if (friendsCount > 0) ...[
                      TextSpan(
                        text: '+$friendsCount amigos seus',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(text: ' e '),
                    ],
                    TextSpan(
                      text: 'outras $totalCount pessoas',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(text: ' já confirmaram.'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
