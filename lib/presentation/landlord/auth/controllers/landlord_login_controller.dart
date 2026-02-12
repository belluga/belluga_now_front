import 'package:belluga_now/domain/repositories/admin_mode_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class LandlordLoginController implements Disposable {
  LandlordLoginController({
    LandlordAuthRepositoryContract? landlordAuthRepository,
    AdminModeRepositoryContract? adminModeRepository,
  })  : _landlordAuthRepository = landlordAuthRepository ??
            GetIt.I.get<LandlordAuthRepositoryContract>(),
        _adminModeRepository =
            adminModeRepository ?? GetIt.I.get<AdminModeRepositoryContract>();

  final LandlordAuthRepositoryContract _landlordAuthRepository;
  final AdminModeRepositoryContract _adminModeRepository;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool get hasValidSession => _landlordAuthRepository.hasValidSession;

  Future<void> loginWithEmailPassword(String email, String password) async {
    await _landlordAuthRepository.loginWithEmailPassword(email, password);
  }

  Future<void> enableAdminMode() async {
    await _adminModeRepository.setLandlordMode();
  }

  Future<bool> enterAdminModeWithCredentials(
    String email,
    String password,
  ) async {
    await loginWithEmailPassword(email, password);
    await enableAdminMode();
    return true;
  }

  Future<bool> ensureAdminMode() async {
    if (!hasValidSession) {
      return false;
    }
    await enableAdminMode();
    return true;
  }

  @override
  void onDispose() {
    emailController.dispose();
    passwordController.dispose();
  }

  void resetForm() {
    emailController.clear();
    passwordController.clear();
  }
}
