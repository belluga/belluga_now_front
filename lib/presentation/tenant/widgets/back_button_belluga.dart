import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

class BackButtonBelluga extends StatelessWidget {
  const BackButtonBelluga({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: context.router.maybePop,
      icon: const Icon(
        Icons.arrow_back_ios,
        // color: Color(0xff212435),
        size: 24,
      ),
    );
  }
}
