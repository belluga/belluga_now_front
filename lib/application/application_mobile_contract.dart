import 'package:flutter/services.dart';
import 'package:unifast_portal/application/application_contract.dart';

abstract class ApplicationMobileContract extends ApplicationContract {
  ApplicationMobileContract({super.key});

  @override
  Future<void> initialSettingsPlatform() async {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
}
