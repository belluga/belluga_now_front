import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:unifast_portal/application/router/app_router.gr.dart';
import 'package:unifast_portal/presentation/common/widgets/profile_action_button/controller/profile_action_button_controller.dart';

class ProfileActionButton extends StatefulWidget {
  const ProfileActionButton({super.key});

  @override
  State<ProfileActionButton> createState() => _ProfileActionButtonState();
}

class _ProfileActionButtonState extends State<ProfileActionButton> {
  final _controller = ProfileActionButtonController();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _navigatoToProfile,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text("Olá, ${_controller.userFirstName}!"),
            SizedBox(width: 20),
            Icon(Icons.person, size: 24),
          ],
        ),
      ),
    );
  }

  void _navigatoToProfile() {
    context.router.push(ProfileRoute());
  }
}
