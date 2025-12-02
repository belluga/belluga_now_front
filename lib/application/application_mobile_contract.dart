import 'package:flutter/services.dart';
import 'package:belluga_now/application/application_contract.dart';

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
