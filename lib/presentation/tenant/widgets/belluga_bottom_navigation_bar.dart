import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:flutter/material.dart';

class BellugaBottomNavigationBar extends StatelessWidget {
  const BellugaBottomNavigationBar({
    super.key,
    required this.currentIndex,
  });

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _onItemTapped(context, index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month),
          label: 'Agenda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_basket_outlined),
          label: 'Mercado',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.travel_explore),
          label: 'Experiencias',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.menu),
          label: 'Menu',
        ),
      ],
    );
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.router.replaceAll([const TenantHomeRoute()]);
        break;
      case 1:
        context.router.replaceAll([const ScheduleRoute()]);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Funcionalidade ainda não disponível.'),
          ),
        );
    }
  }
}
