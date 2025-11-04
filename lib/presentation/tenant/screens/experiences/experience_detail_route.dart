import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/experiences/experience_model.dart';
import 'package:belluga_now/presentation/tenant/screens/experiences/experience_detail_screen.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'ExperienceDetailRoute')
class ExperienceDetailRoutePage extends StatelessWidget {
  const ExperienceDetailRoutePage({
    super.key,
    required this.experience,
  });

  final ExperienceModel experience;

  @override
  Widget build(BuildContext context) {
    return ExperienceDetailScreen(experience: experience);
  }
}
