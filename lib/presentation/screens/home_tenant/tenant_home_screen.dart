import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/configurations/custom_scroll_behavior.dart';
import 'package:belluga_now/presentation/screens/home_tenant/controllers/tenant_home_screen_controller.dart';
import 'package:flutter/material.dart';
import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:get_it/get_it.dart';

@RoutePage()
class TenantHomeScreen extends StatefulWidget {
  const TenantHomeScreen({super.key});

  @override
  State<TenantHomeScreen> createState() => _TenantHomeScreenState();
}

class _TenantHomeScreenState extends State<TenantHomeScreen> {

  late TenantHomeScreenController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GetIt.I.registerSingleton<TenantHomeScreenController>(
      TenantHomeScreenController(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        scrollBehavior: CustomScrollBehavior(),
        slivers: [
          SliverAppBar(
            title: Text(_controller.tenant.name.value),
            centerTitle: true,
            floating: true,
            snap: true,
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return ListTile(
                  title: Text('Item $index'),
                  onTap: () {
                    // Handle item tap
                  },
                );
              },
              childCount: 20, // Example item count
            ),
          ),
        ],
      ),
    );
  }
}
