import 'package:flutter/material.dart';

class InvitesBanner extends StatelessWidget {
  const InvitesBanner({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.secondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Você tem 3 convites pendentes...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            TextButton(
              onPressed: onPressed,
              style: TextButton.styleFrom(
                shape: const StadiumBorder(),
              ),
              child: const Text('Bora?'),
            ),
          ],
        ),
      ),
    );
  }
}