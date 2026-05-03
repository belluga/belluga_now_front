import 'package:flutter/material.dart';

class BackButtonBelluga extends StatelessWidget {
  const BackButtonBelluga({
    super.key,
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onBack,
      icon: const Icon(
        Icons.arrow_back,
        // color: Color(0xff212435),
        size: 24,
      ),
    );
  }
}
