import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

class BellugaConstants {
  static final settings = _SettingsConstants();
  static final api = _ApiConstants();
  static final sentry = _SentryConstants();
}

class _ApiConstants {
  AppData get _appData => GetIt.I.get<AppData>();

  String get adminUrl {
    final String _mainApi = '${_appData.schema}://${_appData.hostname}/admin/api';

    final _environment = dotenv.env["ENV"] ?? "local";

    if (kIsWeb) {
      return _mainApi;
    } else if (Platform.isAndroid) {
      return _environment == "local"
          ? "http://10.0.2.2:5000/api"
          : _mainApi;
    } else {
      return _mainApi;
    }
  }

  String get baseUrl {
    final String _mainApi = '${_appData.schema}://${_appData.hostname}/api';

    final _environment = dotenv.env["ENV"] ?? "local";

    if (kIsWeb) {
      return _mainApi;
    } else if (Platform.isAndroid) {
      return _environment == "local"
          ? "http://10.0.2.2:5000/api"
          : _mainApi;
    } else {
      return _mainApi;
    }
  }
}

class _SettingsConstants {
  String get appID => "com.belluga_now";
  String get platform {
    if (kIsWeb) {
      return "web";
    } else if (Platform.isAndroid) {
      return "android";
    } else if (Platform.isIOS) {
      return "ios";
    } else if (Platform.isWindows) {
      return "windows";
    } else if (Platform.isMacOS) {
      return "macos";
    } else if (Platform.isLinux) {
      return "linux";
    } else {
      return "unknown";
    }
  }
}

class _SentryConstants {
  String get url =>
      "https://1acd2d544ea17269485f5a38c663d0e0@o4504503783784448.ingest.sentry.io/4506716088500224";
  double get tracesSampleRate => 1.0;
}

// class AssetsPath {
//   static String mainLogo  = "assets/images/dark-logo.png";
//   static String productPlaceholder = "assets/images/product_placeholder.png";
//   static String plainIcon = "assets/images/plain_icon.png";
//   static String adaptiveIcon = "assets/images/adaptive_icon.png";
//   static String productImagePlaceholder = "assets/images/product_placeholder.png";
// }

// class Animations {
//   static const _animations = 'assets/animations';
//   static const logo = '$_animations/logo-animation.json';
// }
