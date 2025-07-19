import 'package:flutter/material.dart';
import 'package:unifast_portal/application/configurations/assets_constants.dart';

class AuthHeaderExpandedContent extends StatelessWidget {
  const AuthHeaderExpandedContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(AssetsConstants.login.headerBackground),
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          child: SizedBox.expand(),
        ),
        SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Transform.flip(
                flipX: true,
                child: Image.asset(
                  AssetsConstants.login.headerArt,
                  fit: BoxFit.fitWidth,
                  // width: 200,
                  // height: 200,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
