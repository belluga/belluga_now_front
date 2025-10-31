import 'package:flutter/material.dart';

class MainLogo extends StatelessWidget {
  const MainLogo({
    super.key,
    this.width = 120,
    this.height = 32,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo_horizontal.png',
      width: width,
      height: height,
      fit: BoxFit.contain,
      semanticLabel: 'Belluga Now Logo',
    );
  }
}
