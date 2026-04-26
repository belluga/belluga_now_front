import 'package:belluga_now/presentation/tenant_public/schedule/widgets/agenda_radius_sheet_presentation.dart';
import 'package:flutter/widgets.dart';

class AgendaAppBarActions {
  const AgendaAppBarActions({
    this.showBack = false,
    this.showSearch = true,
    this.leadingActions = const <Widget>[],
    this.showRadius = true,
    this.showInviteFilter = true,
    this.showHistory = true,
    this.radiusSheetPresentation,
  });

  final bool showBack;
  final bool showSearch;
  final List<Widget> leadingActions;
  final bool showRadius;
  final bool showInviteFilter;
  final bool showHistory;
  final AgendaRadiusSheetPresentation? radiusSheetPresentation;
}
