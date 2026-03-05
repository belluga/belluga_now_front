import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

abstract class LandlordLoginSheetControllerContract implements Disposable {
  TextEditingController get emailController;
  TextEditingController get passwordController;

  bool get hasValidSession;

  Future<void> loginWithEmailPassword(String email, String password);

  Future<void> enableAdminMode();

  Future<bool> enterAdminModeWithCredentials(String email, String password);

  Future<bool> ensureAdminMode();

  void resetForm();
}
