export 'application_mobile.dart' // A fallback for unsupported platforms
    if (dart.library.js_interop) 'application_web.dart'
    if (dart.library.io) 'application_mobile.dart';
