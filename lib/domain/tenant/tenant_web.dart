import 'dart:js_interop';

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

class Tenant {
  late String? port;
  late String hostname;
  late String href;
  late String device;

  Tenant();

  Future<void> initialize() async {
    port = appDataJS.port;
    hostname = appDataJS.hostname;
    href = appDataJS.href;
    device = "web";
  }
  
  

  String get schema => href.split(hostname).first;
}
