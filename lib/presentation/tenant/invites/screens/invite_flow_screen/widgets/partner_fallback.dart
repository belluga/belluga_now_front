import 'package:flutter/material.dart';

class PartnerFallbackView extends StatelessWidget {
  const PartnerFallbackView({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Detalhes do parceiro $name indisponíveis no momento.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
