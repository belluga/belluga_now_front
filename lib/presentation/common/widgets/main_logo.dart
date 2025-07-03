import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class MainLogo extends StatelessWidget {
  const MainLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/logo.svg',
      width: 90,
      height: 36,
      fit: BoxFit.cover,
      semanticsLabel: 'Unifast Logo',
    );
  }
}
