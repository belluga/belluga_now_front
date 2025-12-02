import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/common/widgets/profile_action_button/controllers/profile_action_button_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class ProfileActionButton extends StatefulWidget {
  const ProfileActionButton({super.key}) : controller = null;

  @visibleForTesting
  const ProfileActionButton.withController(
    this.controller, {
    super.key,
  });

  final ProfileActionButtonController? controller;

  @override
  State<ProfileActionButton> createState() => _ProfileActionButtonState();
}

class _ProfileActionButtonState extends State<ProfileActionButton> {
  ProfileActionButtonController get _controller =>
      widget.controller ?? GetIt.I.get<ProfileActionButtonController>();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _navigateToProfile,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Olá, ${_controller.userFirstName}!'),
            const SizedBox(width: 20),
            const Icon(Icons.person, size: 24),
          ],
        ),
      ),
    );
  }

  void _navigateToProfile() {
    context.router.push(ProfileRoute());
  }
}
