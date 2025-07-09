import 'package:flutter/material.dart';
import 'package:unifast_portal/application/application.dart';
import 'package:unifast_portal/application/configurations/belluga_constants.dart';
import 'package:get_it/get_it.dart';
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  GetIt.I.registerSingleton<Application>(Application());

  await SentryFlutter.init(
    (options) {
      options.dsn = BellugaConstants.sentry.url;
      options.tracesSampleRate = BellugaConstants.sentry.tracesSampleRate;
    },
    appRunner: () async {
      try {
        await GetIt.I.get<Application>().init();
        runApp(GetIt.I.get<Application>());
      } catch (error, stackTrace) {
        await Sentry.captureException(error, stackTrace: stackTrace);
        rethrow;
      }
    },
  );

  // final _pushHandler =
  //     PushHandler(onbackgroundStartMessage: _onBackgroundMessage)
}

// void _initApp() {
  
//   runApp(
//     Application(
        // pushHandler: _pushHandler,
        // authRepository: _authRepository,
        // bellugaApp: _bellugaApp,
//         ),
//   );
// }

// Future<void> _onBackgroundMessage(message) async =>
//     await PushHandler.onBackgroundMessage(message);
