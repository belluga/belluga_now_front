import 'package:belluga_now/domain/repositories/admin_mode_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/presentation/landlord_area/auth/controllers/landlord_login_sheet_controller_contract.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

abstract class LandlordLoginControllerBase
    implements LandlordLoginSheetControllerContract {
  LandlordLoginControllerBase({
    LandlordAuthRepositoryContract? landlordAuthRepository,
    AdminModeRepositoryContract? adminModeRepository,
  })  : _landlordAuthRepository = landlordAuthRepository ??
            GetIt.I.get<LandlordAuthRepositoryContract>(),
        _adminModeRepository =
            adminModeRepository ?? GetIt.I.get<AdminModeRepositoryContract>();

  final LandlordAuthRepositoryContract _landlordAuthRepository;
  final AdminModeRepositoryContract _adminModeRepository;

  @override
  final TextEditingController emailController = TextEditingController();
  @override
  final TextEditingController passwordController = TextEditingController();

  @override
  bool get hasValidSession => _landlordAuthRepository.hasValidSession;

  @override
  Future<void> loginWithEmailPassword(String email, String password) async {
    await _landlordAuthRepository.loginWithEmailPassword(email, password);
  }

  @override
  Future<void> enableAdminMode() async {
    await _adminModeRepository.setLandlordMode();
  }

  @override
  Future<bool> enterAdminModeWithCredentials(
    String email,
    String password,
  ) async {
    await loginWithEmailPassword(email, password);
    await enableAdminMode();
    return true;
  }

  @override
  Future<bool> ensureAdminMode() async {
    if (!hasValidSession) {
      return false;
    }
    await enableAdminMode();
    return true;
  }

  @override
  void resetForm() {
    emailController.clear();
    passwordController.clear();
  }

  @override
  void onDispose() {
    emailController.dispose();
    passwordController.dispose();
  }
}
