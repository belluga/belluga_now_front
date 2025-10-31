import 'package:flutter/material.dart';

class WidgetKeys {
  static final auth = _WidgetKeysAuth();
  static final splash = _WidgetKeysSplash();
}

class _WidgetKeysAuth {
  Key get navigateToProtectedButton => const Key("go_to_protected_button");
  Key get navigateToSignupButton => const Key("go_to_signup_button");
  Key get navigateToRecoverButton => const Key("go_to_recover_button");
  Key get loginEmailField => const Key("login_email_field");
  Key get loginPasswordField => const Key("login_password_field");
  Key get loginButton => const Key("login_button");
  Key get logoutButton => const Key("logout_button");
  Key get signupNameField => const Key("signup_name_field");
  Key get signupEmailField => const Key("signup_email_field");
  Key get signupPasswordField => const Key("signup_password_field");
  Key get signupButton => const Key("signup_button");
  Key get recoverButton => const Key("recover_button");
  Key get recoverEmailField => const Key("recover_email_field");
  Key get newPasswordField => const Key("new_password_field");
  Key get newPasswordConfirmField => const Key("new_password_confirm_field");
}

class _WidgetKeysSplash {
  Key get scaffold => const Key("splash_scaffold");
}
