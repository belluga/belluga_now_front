String normalizePath(String path) => path.replaceAll('\\\\', '/');

bool _containsSegment(String path, String segment) {
  final normalized = normalizePath(path);
  return normalized.contains(segment);
}

bool isPresentationFilePath(String path) {
  return _containsSegment(path, '/lib/presentation/');
}

bool isUiPresentationFilePath(String path) {
  if (!isPresentationFilePath(path)) {
    return false;
  }

  final normalized = normalizePath(path);
  if (_containsSegment(normalized, '/controllers/')) {
    return false;
  }

  return _containsSegment(normalized, '/screens/') ||
      _containsSegment(normalized, '/widgets/') ||
      normalized.endsWith('_screen.dart') ||
      normalized.endsWith('_widget.dart');
}

bool isPresentationWidgetFilePath(String path) {
  if (!isPresentationFilePath(path)) {
    return false;
  }

  final normalized = normalizePath(path);
  if (_containsSegment(normalized, '/controllers/')) {
    return false;
  }

  return _containsSegment(normalized, '/widgets/') ||
      normalized.endsWith('_widget.dart');
}

bool isPresentationScreenFilePath(String path) {
  if (!isPresentationFilePath(path)) {
    return false;
  }

  final normalized = normalizePath(path);
  if (_containsSegment(normalized, '/controllers/')) {
    return false;
  }

  if (isPresentationWidgetFilePath(normalized)) {
    return false;
  }

  return _containsSegment(normalized, '/screens/') ||
      normalized.endsWith('_screen.dart');
}

bool isDomainFilePath(String path) {
  return _containsSegment(path, '/lib/domain/');
}

bool isPresentationControllerFilePath(String path) {
  final normalized = normalizePath(path);
  return _containsSegment(normalized, '/lib/presentation/') &&
      _containsSegment(normalized, '/controllers/');
}

bool isModularModuleFilePath(String path) {
  return _containsSegment(path, '/lib/application/router/modular_app/modules/');
}

bool isAllowedGlobalRegistrationFilePath(String path) {
  final normalized = normalizePath(path);

  return normalized.endsWith('/lib/main.dart') ||
      normalized.endsWith('/lib/application/router/modular_app/module_settings.dart') ||
      normalized.endsWith('/lib/infrastructure/repositories/app_data_repository.dart');
}

String? presentationRootKey(String path) {
  final normalized = normalizePath(path);
  const marker = '/lib/presentation/';
  final markerIndex = normalized.indexOf(marker);
  if (markerIndex == -1) {
    return null;
  }

  final relative = normalized.substring(markerIndex + marker.length);
  final segments = relative.split('/');
  if (segments.length < 2) {
    return null;
  }

  return '${segments[0]}/${segments[1]}';
}

bool isSharedPresentationRootKey(String rootKey) {
  return rootKey.startsWith('shared/');
}
