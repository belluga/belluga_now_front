import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/tenant/auth/login/controllers/auth_login_controller_contract.dart';
import 'package:belluga_now/presentation/common/widgets/main_logo.dart';
import 'package:flutter/material.dart';
import 'package:belluga_now/presentation/common/auth/screens/auth_login_screen/widgets/auth_header_expanded_content.dart';
import 'package:belluga_now/presentation/common/auth/screens/auth_login_screen/widgets/auth_header_headline.dart';
import 'package:belluga_now/presentation/common/auth/screens/auth_login_screen/widgets/auth_login_canva_content.dart';
import 'package:get_it/get_it.dart';

class AuthLoginScreen extends StatefulWidget {
  const AuthLoginScreen({super.key});

  @override
  State<AuthLoginScreen> createState() => _AuthLoginScreenState();
}

class _AuthLoginScreenState extends State<AuthLoginScreen>
    with WidgetsBindingObserver {
  late final AuthLoginControllerContract _controller =
      GetIt.I.get<AuthLoginControllerContract>();

  @override
  void initState() {
    super.initState();

    _controller.generalErrorStreamValue.stream.listen(_onGeneralError);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _controller.sliverAppBarController.scrollController,
        slivers: [
          SliverAppBar(
            elevation: 0,
            automaticallyImplyLeading: true,
            collapsedHeight:
                _controller.sliverAppBarController.collapsedBarHeight,
            expandedHeight:
                _controller.sliverAppBarController.expandedBarHeight,
            pinned: true,
            backgroundColor: Theme.of(context).primaryColor,
            title: MainLogo(),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: AuthHeaderExpandedContent(),
            ),
          ),
          PinnedHeaderSliver(child: AuthHeaderHeadline()),
          PinnedHeaderSliver(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 24),
                child: AuthLoginCanvaContent(
                  navigateToPasswordRecover: _navigateToPasswordRecover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();

    _listenKeyboardState();
  }

  void _listenKeyboardState() {
    final keyboardIsOpened = View.of(context).viewInsets.bottom > 0;

    _controller.sliverAppBarController.keyboardIsOpened.addValue(
      keyboardIsOpened,
    );

    if (keyboardIsOpened) {
      _shrinkSliverAppBar();
    } else {
      _expandSliverAppBar();
    }
  }

  void _shrinkSliverAppBar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.sliverAppBarController.shrink();
    });
  }

  void _expandSliverAppBar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.sliverAppBarController.expand();
    });
  }

  void _onGeneralError(String? error) {
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(_messageSnack);
    }
  }

  Future<void> _navigateToPasswordRecover() async {
    final emailReturned = await context.router.push<String>(
      RecoveryPasswordRoute(
        initialEmmail: _controller.authEmailFieldController.text,
      ),
    );

    _controller.authEmailFieldController.textController.text =
        emailReturned ?? _controller.authEmailFieldController.text;
  }

  SnackBar get _messageSnack {
    return SnackBar(
      closeIconColor: Theme.of(context).colorScheme.onError,
      showCloseIcon: true,
      backgroundColor: Theme.of(context).colorScheme.error,
      content: SizedBox(
        child: Center(
          child: Text(
            _controller.generalErrorStreamValue.value ?? "",
            style: TextTheme.of(context).bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onError,
                ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _controller.onDispose();
  }
}
