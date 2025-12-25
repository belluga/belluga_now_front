import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_provisional_screen/widgets/agenda_section/controllers/tenant_home_agenda_controller.dart';
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
      searchActiveStreamValue: controller.searchActiveStreamValue,
      searchController: controller.searchController,
      focusNode: controller.focusNode,
      onToggleSearchMode: controller.toggleSearchMode,
      onSearchChanged: controller.searchEvents,
      maxRadiusMetersStreamValue: controller.maxRadiusMetersStreamValue,
      radiusMetersStreamValue: controller.radiusMetersStreamValue,
      onSetRadiusMeters: controller.setRadiusMeters,
      inviteFilterStreamValue: controller.inviteFilterStreamValue,
      onCycleInviteFilter: controller.cycleInviteFilter,
      showHistoryStreamValue: controller.showHistoryStreamValue,
      onToggleHistory: controller.toggleHistory,
      actions: const AgendaAppBarActions(
        showSearch: true,
        showRadius: true,
        showInviteFilter: true,
        showHistory: false,
      ),
    );
  }
}
