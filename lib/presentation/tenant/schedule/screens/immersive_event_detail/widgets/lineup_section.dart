import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:flutter/material.dart';

class LineupSection extends StatelessWidget {
  const LineupSection({
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
            'Line-up',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (event.artists.isEmpty)
            const Text('Nenhum artista confirmado ainda.')
          else
            ...event.artists.map((artist) {
              return ListTile(
                leading: artist.avatarUri != null
                    ? CircleAvatar(
                        backgroundImage:
                            NetworkImage(artist.avatarUri.toString()),
                      )
                    : const CircleAvatar(child: Icon(Icons.person)),
                title: Text(artist.displayName),
                trailing: artist.isHighlight
                    ? const Icon(Icons.star, color: Colors.amber)
                    : null,
              );
            }),
        ],
      ),
    );
  }
}
