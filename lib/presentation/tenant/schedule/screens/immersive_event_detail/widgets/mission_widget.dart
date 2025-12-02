import 'package:belluga_now/domain/gamification/mission_resume.dart';
import 'package:flutter/material.dart';

class MissionWidget extends StatelessWidget {
  const MissionWidget({
    required this.mission,
    super.key,
  });

  final MissionResume mission;

  @override
  Widget build(BuildContext context) {
    final isCompleted =
        mission.isCompleted || mission.progress >= mission.totalRequired;
    final primaryColor = const Color(0xFFD4AF37); // Gold-ish for mission

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? Colors.green : primaryColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                isCompleted ? Icons.emoji_events_outlined : Icons.star,
                color: isCompleted ? Colors.green : primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                isCompleted ? 'Missão Cumprida!' : 'Missão Ativa',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCompleted ? Colors.green : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            mission.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),

          // Description
          Text(
            mission.description,
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(height: 16),

          // Progress or Code
          if (isCompleted) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Código do Prêmio:'),
                  Text(
                    mission.reward,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Monospace',
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Seu Status: Falta ${mission.totalRequired - mission.progress} amigo(s)!',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${(mission.progressPercentage * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: mission.progressPercentage,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
