import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/application/router/app_router.gr.dart';

class ProfileButton extends StatefulWidget {
  const ProfileButton({super.key});

  @override
  State<ProfileButton> createState() => _ProfileButtonState();
}

class _ProfileButtonState extends State<ProfileButton> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: gotoProfile,
      child: const CircleAvatar());
  }

  void gotoProfile(){
    context.router.push(const ProfileRoute());
  }
}