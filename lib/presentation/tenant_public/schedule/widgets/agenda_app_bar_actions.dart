import 'package:belluga_now/presentation/tenant_public/schedule/widgets/agenda_radius_sheet_presentation.dart';

class AgendaAppBarActions {
  const AgendaAppBarActions({
    this.showBack = false,
    this.showSearch = true,
    this.showRadius = true,
    this.showInviteFilter = true,
    this.showHistory = true,
    this.radiusSheetPresentation,
  });

  final bool showBack;
  final bool showSearch;
  final bool showRadius;
  final bool showInviteFilter;
  final bool showHistory;
  final AgendaRadiusSheetPresentation? radiusSheetPresentation;
}
