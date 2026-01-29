// AppData backend selector.
// - Mobile/Desktop: uses the Dio-based stub (`app_data_backend_stub.dart`) to
//   call the Laravel `/api/v1/environment` endpoint on the main domain with the app domain.
// - Web: listens for the `brandingReady` custom event emitted by the host
//   page and parses the branding payload (`app_data_backend_web.dart`).
export 'app_data_backend_stub.dart'
    if (dart.library.js_interop) 'app_data_backend_web.dart';
