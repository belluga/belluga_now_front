import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:flutter/material.dart';

class EventInfoSection extends StatelessWidget {
  const EventInfoSection({
    required this.event,
    super.key,
  });

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16).copyWith(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'O Rolê',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            event.content.value ?? 'Sem descrição disponível.',
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
          // TODO: Add more event details
        ],
      ),
    );
  }
}
