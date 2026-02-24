import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:flutter/material.dart';

class MainLogo extends StatelessWidget {
  const MainLogo({
    super.key,
    required this.appData,
    this.width = 120,
    this.height = 32,
  });

  final AppData appData;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final logoUri = brightness == Brightness.dark
        ? appData.mainLogoDarkUrl.value
        : appData.mainLogoLightUrl.value;
    debugPrint(
      '[MainLogo] brightness=$brightness -> uri=${logoUri?.toString()}',
    );
    return BellugaNetworkImage(
      logoUri!.toString(),
      width: width,
      height: height,
      fit: BoxFit.contain,
      semanticLabel: 'Belluga Now Logo',
    );
  }
}
