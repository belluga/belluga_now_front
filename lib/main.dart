import 'package:flutter/material.dart';
import 'package:belluga_now/application/application_contract.dart';
import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:get_it/get_it.dart';
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:belluga_now/application/application.dart';

Future<void> main() async {
  GetIt.I.registerSingleton<ApplicationContract>(Application());

  await SentryFlutter.init(
    (options) {
      options.dsn = BellugaConstants.sentry.url;
      options.tracesSampleRate = BellugaConstants.sentry.tracesSampleRate;
    },
    appRunner: () async {
      try {
        await GetIt.I.get<ApplicationContract>().init();
        runApp(GetIt.I.get<ApplicationContract>());
      } catch (error, stackTrace) {
        await Sentry.captureException(error, stackTrace: stackTrace);
        rethrow;
      }
    },
  );
}