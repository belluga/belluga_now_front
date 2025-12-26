import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/agenda_section/controllers/tenant_home_agenda_controller.dart';
import 'package:belluga_now/presentation/tenant/schedule/widgets/agenda_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class HomeAgendaAppBar extends StatelessWidget {
  const HomeAgendaAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = GetIt.I.get<TenantHomeAgendaController>();
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
