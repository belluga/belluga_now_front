export 'home_agenda_section_slots.dart';

import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/agenda_section/controllers/tenant_home_agenda_controller.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/agenda_section/home_agenda_section_view.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/agenda_section/home_agenda_section_slots.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class HomeAgendaSection extends StatefulWidget {
  const HomeAgendaSection({
    super.key,
    required this.builder,
    this.scrollController,
  });

  final Widget Function(BuildContext context, HomeAgendaSectionSlots slots)
      builder;
  final ScrollController? scrollController;

  @override
  State<HomeAgendaSection> createState() => _HomeAgendaSectionState();
}

class _HomeAgendaSectionState extends State<HomeAgendaSection> {
  late final TenantHomeAgendaController _controller =
      GetIt.I.get<TenantHomeAgendaController>();

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    await _controller.init(startWithHistory: false);
  }

  @override
  void dispose() {
    _controller.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HomeAgendaSectionView(
      controller: _controller,
      builder: widget.builder,
      scrollController: widget.scrollController,
    );
  }
}
