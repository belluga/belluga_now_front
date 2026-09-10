import 'package:flutter/material.dart';

class AccountProfileFallbackView extends StatelessWidget {
  const AccountProfileFallbackView({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Detalhes do perfil $name indisponíveis no momento.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
