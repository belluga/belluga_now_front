import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/agenda_section/controllers/tenant_home_agenda_controller.dart';
import 'package:belluga_now/presentation/tenant/schedule/widgets/agenda_app_bar.dart';
import 'package:flutter/material.dart';

class HomeAgendaAppBar extends StatelessWidget {
  const HomeAgendaAppBar({
    super.key,
    required this.controller,
  });

  final TenantHomeAgendaController controller;

  @override
  Widget build(BuildContext context) {
    return AgendaAppBar(
      controller: controller,
      actions: const AgendaAppBarActions(
        showSearch: true,
        showRadius: true,
        showInviteFilter: true,
        showHistory: false,
      ),
    );
  }
}
