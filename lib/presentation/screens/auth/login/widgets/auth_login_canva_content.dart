import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:belluga_now/domain/controllers/auth_login_controller_contract.dart';
import 'package:belluga_now/presentation/common/widgets/button_loading.dart';
import 'package:belluga_now/presentation/screens/auth/login/widgets/auth_login_form.dart';
import 'package:get_it/get_it.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class AuthLoginCanvaContent extends StatefulWidget {
  final Future<void> Function() navigateToPasswordRecover;

  const AuthLoginCanvaContent({
    super.key,
    required this.navigateToPasswordRecover,
  });

  @override
  State<AuthLoginCanvaContent> createState() => _AuthLoginCanvaContentState();
}

class _AuthLoginCanvaContentState extends State<AuthLoginCanvaContent>
    with WidgetsBindingObserver {
  final _controller = GetIt.I.get<AuthLoginControllerContract>();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        StreamValueBuilder(
          streamValue: _controller.sliverAppBarController.keyboardIsOpened,
          builder: (context, isOpened) {
            if (isOpened) {
              return const SizedBox.shrink();
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Entrar", style: TextTheme.of(context).titleLarge),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
        AuthLoginnForm(),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Esqueci minha senha.",
                  style: TextStyle(fontSize: 12),
                ),
                TextButton(
                  onPressed: widget.navigateToPasswordRecover,
                  child: const Text(
                    "Recuperar agora",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 20),
        ButtonLoading(
          onPressed: tryLoginWithEmailPassword,
          loadingStatusStreamValue: _controller.buttonLoadingValue,
          label: "Entrar",
        ),
        // const SizedBox(height: 30),
      ],
    );
  }

  Future<void> tryLoginWithEmailPassword() async {
    await _controller.tryLoginWithEmailPassword();
    _navigateToAuthorizedPage();
  }

  Future<void> _navigateToAuthorizedPage() async =>
      await context.router.replace(const DashboardRoute());

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }
}
