import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/invites_banner/controllers/invites_banner_builder_controller.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/invites_banner/invites_banner_view.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class InvitesBannerBuilder extends StatefulWidget {
  const InvitesBannerBuilder({
    super.key,
    required this.onPressed,
    this.margin,
  });

  final VoidCallback onPressed;
  final EdgeInsets? margin;

  @override
  State<InvitesBannerBuilder> createState() => _InvitesBannerBuilderState();
}

class _InvitesBannerBuilderState extends State<InvitesBannerBuilder> {
  late final InvitesBannerBuilderController _controller =
      GetIt.I.get<InvitesBannerBuilderController>();

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  void dispose() {
    _controller.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InvitesBannerView(
      controller: _controller,
      onPressed: widget.onPressed,
      margin: widget.margin,
    );
  }
}
