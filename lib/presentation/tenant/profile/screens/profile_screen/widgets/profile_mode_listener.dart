import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/repositories/admin_mode_repository_contract.dart';
import 'package:flutter/material.dart';

class ProfileModeListener extends StatefulWidget {
  const ProfileModeListener({
    super.key,
    required this.mode,
    required this.child,
  });

  final AdminMode mode;
  final Widget child;

  @override
  State<ProfileModeListener> createState() => _ProfileModeListenerState();
}

class _ProfileModeListenerState extends State<ProfileModeListener> {
  AdminMode? _lastMode;

  @override
  void initState() {
    super.initState();
    _handleMode(widget.mode);
  }

  @override
  void didUpdateWidget(covariant ProfileModeListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    _handleMode(widget.mode);
  }

  void _handleMode(AdminMode mode) {
    if (_lastMode == mode) return;
    _lastMode = mode;
    if (mode == AdminMode.landlord) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.router.replaceAll([const TenantAdminShellRoute()]);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
