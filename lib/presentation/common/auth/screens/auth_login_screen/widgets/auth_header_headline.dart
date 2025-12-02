import 'package:flutter/material.dart';
import 'package:belluga_now/application/configurations/assets_constants.dart';

class AuthHeaderHeadline extends StatelessWidget {
  const AuthHeaderHeadline({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(AssetsConstants.login.headerBackground),
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
              ),
            ),
            child: SizedBox.expand(),
          ),
          Container(
            color: Colors.transparent,
            height: 50,
            alignment: Alignment.center,
            child: Text(
              "Bem vindo à educação do Futuro",
              style: TextTheme.of(context).titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
