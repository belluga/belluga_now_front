import 'dart:js_interop';
import 'package:belluga_now/application/app_data.dart';

// Your JS interop definitions remain the same
@JS()
@staticInterop
@anonymous
class AppDataJS {}

extension AppDataExtension on AppDataJS {
  external String get hostname;
  external String get href;
  external String get port;
}

@JS()
@staticInterop
external AppDataJS get appDataJS;

Future<AppData> getPlatformAppData() async {
  return AppData(
    port: appDataJS.port,
    hostname: appDataJS.hostname,
    href: appDataJS.href,
  );
}
