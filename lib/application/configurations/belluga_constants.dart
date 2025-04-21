import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class BellugaConstants {
  static final settings = _SettingsConstants();
  static final api = _ApiConstants();
  static final sentry = _SentryConstants();
  static final realm = _RealmConstants();
}

class _ApiConstants {
  String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api';
    }else if(Platform.isAndroid){
      return dotenv.env["API_URL_ANDROID"] ??
          "http://10.0.2.2:8000/api";
    }else{
      return dotenv.env["API_URL_DEFAULT"] ??
          "http://localhost:8000/api";
    }
  } 
  String get login => "$baseUrl/auth/login";
  String get authGetUser =>
      "https://services.cloud.mongodb.com/api/client/v2.0/app/application-0-gwvgn/auth/providers/custom-token/login";
}

class _SettingsConstants {
  String get appID => "com.boilerplate.belluga.app";
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

class _RealmConstants {
  String get appId => "application-0-gwvgn";
  String get userDataCollection => "userData";
  String get userDatabase => "data";
  _RealmFunctions get functions => _RealmFunctions();
}

class _RealmFunctions {
  String get updateUser => "userUpdate";
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