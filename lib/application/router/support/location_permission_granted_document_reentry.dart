import 'location_permission_granted_document_reentry_stub.dart'
    if (dart.library.js_interop) 'location_permission_granted_document_reentry_web.dart'
    as impl;

typedef LocationPermissionGrantedDocumentReentry = bool Function(
  String redirectPath,
);

bool performLocationPermissionGrantedDocumentReentry(String redirectPath) {
  return impl.performLocationPermissionGrantedDocumentReentry(redirectPath);
}
