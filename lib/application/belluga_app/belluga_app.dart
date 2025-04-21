// import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_laravel_backend_boilerplate/application/belluga_app/belluga_app_contract.dart';

class BellugaApp extends BellugaAppContract {
  BellugaApp();

  @override
  Future<void> initialize() async {
    await super.initialize();
    // await initializeFirebase();

    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  }

  // Future<void> initializeFirebase() async {
  //   await Firebase.initializeApp();
  // }
}
