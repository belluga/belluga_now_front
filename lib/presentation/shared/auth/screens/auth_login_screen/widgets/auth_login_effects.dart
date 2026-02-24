import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:flutter/material.dart';

class AuthLoginEffects extends StatefulWidget {
  const AuthLoginEffects({
    super.key,
    required this.child,
    required this.generalError,
    required this.loginResult,
    required this.signUpResult,
    required this.onClearGeneralError,
    required this.onClearLoginResult,
    required this.onClearSignUpResult,
  });

  final Widget child;
  final String? generalError;
  final bool? loginResult;
  final bool? signUpResult;
  final VoidCallback onClearGeneralError;
  final VoidCallback onClearLoginResult;
  final VoidCallback onClearSignUpResult;

  @override
  State<AuthLoginEffects> createState() => _AuthLoginEffectsState();
}

class _AuthLoginEffectsState extends State<AuthLoginEffects> {
  String? _lastGeneralError;
  bool? _lastLoginResult;
  bool? _lastSignUpResult;

  @override
  void initState() {
    super.initState();
    _resetIfCleared();
    _handleGeneralError(widget.generalError);
    _handleLoginResult(widget.loginResult);
    _handleSignUpResult(widget.signUpResult);
  }

  @override
  void didUpdateWidget(covariant AuthLoginEffects oldWidget) {
    super.didUpdateWidget(oldWidget);
    _resetIfCleared();
    _handleGeneralError(widget.generalError);
    _handleLoginResult(widget.loginResult);
    _handleSignUpResult(widget.signUpResult);
  }

  void _resetIfCleared() {
    if (widget.generalError == null || widget.generalError!.isEmpty) {
      _lastGeneralError = null;
    }
    if (widget.loginResult == null) {
      _lastLoginResult = null;
    }
    if (widget.signUpResult == null) {
      _lastSignUpResult = null;
    }
  }

  void _handleGeneralError(String? error) {
    if (error == null || error.isEmpty) return;
    if (error == _lastGeneralError) return;
    _lastGeneralError = error;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(_buildErrorSnack(error));
      widget.onClearGeneralError();
    });
  }

  void _handleLoginResult(bool? authorized) {
    if (authorized == null) return;
    if (authorized == _lastLoginResult) return;
    _lastLoginResult = authorized;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (authorized) {
        _navigateAfterAuth();
      }
      widget.onClearLoginResult();
    });
  }

  void _handleSignUpResult(bool? authorized) {
    if (authorized == null) return;
    if (authorized == _lastSignUpResult) return;
    _lastSignUpResult = authorized;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (authorized) {
        final rootRouter = context.router.root;
        if (rootRouter.canPop()) {
          rootRouter.pop();
        }
        _navigateAfterAuth();
      }
      widget.onClearSignUpResult();
    });
  }

  void _navigateAfterAuth() {
    final router = context.router;
    final pendingPath = _readRedirectPathFromQuery();
    if (pendingPath != null && !pendingPath.contains('/auth/login')) {
      router.replacePath(pendingPath);
      return;
    }
    if (router.canPop()) {
      router.pop();
      return;
    }
    router.replace(const TenantHomeRoute());
  }

  String? _readRedirectPathFromQuery() {
    final value = context.routeData.queryParams.rawMap['redirect'];
    if (value == null) {
      return null;
    }
    final redirect = value.toString().trim();
    if (redirect.isEmpty) {
      return null;
    }
    return Uri.decodeComponent(redirect);
  }

  SnackBar _buildErrorSnack(String message) {
    final colorScheme = Theme.of(context).colorScheme;
    return SnackBar(
      closeIconColor: colorScheme.onError,
      showCloseIcon: true,
      backgroundColor: colorScheme.error,
      content: SizedBox(
        child: Center(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onError,
                ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
