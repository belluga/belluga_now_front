export 'menu_action.dart';

import 'package:belluga_now/presentation/tenant_public/menu/screens/menu_screen/models/menu_action.dart';

class MenuSection {
  const MenuSection({required this.title, required this.actions});

  final String title;
  final List<MenuAction> actions;
}
