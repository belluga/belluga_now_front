import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

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
    final appData = GetIt.I.get<AppData>();
    final brightness = Theme.of(context).brightness;
    final logoUri = brightness == Brightness.dark
        ? appData.mainLogoDarkUrl.value
        : appData.mainLogoLightUrl.value;
    debugPrint(
      '[MainLogo] brightness=$brightness -> uri=${logoUri?.toString()}',
    );
    return Image.network(
      logoUri!.toString(),
      width: width,
      height: height,
      fit: BoxFit.contain,
      semanticLabel: 'Belluga Now Logo',
    );
  }
}
