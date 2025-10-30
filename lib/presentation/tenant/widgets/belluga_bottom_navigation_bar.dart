import 'package:flutter/material.dart';

class BellugaBottomNavigationBar extends StatelessWidget {
  const BellugaBottomNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {

    return BottomNavigationBar(
      currentIndex: 0,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.add),
          label: "Início",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month),
          label: "Agenda",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_basket_outlined),
          label: "Mercado",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.travel_explore),
          label: "Experiências",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.menu),
          label: "Menu",
        ),
      ],
    );
  }
}
