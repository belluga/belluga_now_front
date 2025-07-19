export 'get_app_data_mobile.dart' // A fallback for unsupported platforms
    if (dart.library.html) 'get_app_data_web.dart'
    if (dart.library.io) 'get_app_data_mobile.dart';