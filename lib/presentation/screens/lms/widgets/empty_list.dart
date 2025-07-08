import 'package:flutter/material.dart';

class EmptyListMessage extends StatelessWidget {
  const EmptyListMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: SizedBox(
            height: 200,
            child: Text(
              "Nenhum arquivo disponível.",
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
