String normalizePath(String path) => path.replaceAll('\\\\', '/');

bool _containsSegment(String path, String segment) {
  final normalized = normalizePath(path);
  if (segment.isEmpty) {
    return false;
  }

  final withLeadingSlash = segment.startsWith('/') ? segment : '/$segment';
  final withoutLeadingSlash = withLeadingSlash.substring(1);
  final withoutLibPrefix = withoutLeadingSlash.startsWith('lib/')
      ? withoutLeadingSlash.substring(4)
      : withoutLeadingSlash;

  if (normalized.contains(withLeadingSlash) ||
      normalized.contains(withoutLeadingSlash) ||
      normalized.startsWith(withoutLeadingSlash)) {
    return true;
  }

  if (normalized.startsWith('package:')) {
    final firstSlash = normalized.indexOf('/');
    if (firstSlash != -1 && firstSlash + 1 < normalized.length) {
      final packageRelative = normalized.substring(firstSlash + 1);
      if (packageRelative.contains(withoutLeadingSlash) ||
          packageRelative.startsWith(withoutLeadingSlash) ||
          packageRelative.contains(withoutLibPrefix) ||
          packageRelative.startsWith(withoutLibPrefix)) {
        return true;
      }
    }
  }

  return false;
}

bool isPresentationFilePath(String path) {
  return _containsSegment(path, '/lib/presentation/');
}

bool isLibFilePath(String path) {
  final normalized = normalizePath(path);
  return _containsSegment(normalized, '/lib/') || normalized.startsWith('lib/');
}

bool isGeneratedFilePath(String path) {
  final normalized = normalizePath(path);
  return normalized.endsWith('.g.dart') ||
      normalized.endsWith('.freezed.dart') ||
      normalized.endsWith('.gr.dart') ||
      normalized.endsWith('.mocks.dart');
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

bool isPresentationRouteFilePath(String path) {
  if (!isPresentationFilePath(path)) {
    return false;
  }

  final normalized = normalizePath(path);
  return _containsSegment(normalized, '/routes/');
}

bool isDomainFilePath(String path) {
  return _containsSegment(path, '/lib/domain/');
}

bool isDomainRepositoryContractFilePath(String path) {
  final normalized = normalizePath(path);
  if (!_containsSegment(normalized, '/lib/domain/repositories/')) {
    return false;
  }

  return normalized.endsWith('_repository_contract.dart') ||
      normalized.contains('repository_contract_') ||
      normalized.endsWith('repository_contract_case.dart');
}

bool isScheduleRepositoryContractFilePath(String path) {
  final normalized = normalizePath(path);
  return normalized.endsWith(
        '/lib/domain/repositories/schedule_repository_contract.dart',
      ) ||
      normalized.endsWith('repository_contract_pagination_case.dart');
}

bool isDomainScheduleFilePath(String path) {
  final normalized = normalizePath(path);
  return _containsSegment(normalized, '/lib/domain/schedule/') ||
      normalized.endsWith('paged_result_type_case.dart');
}

bool isDomainValueObjectFilePath(String path) {
  final normalized = normalizePath(path);
  return isDomainFilePath(normalized) &&
      (_containsSegment(normalized, '/value_objects/') ||
          _containsSegment(normalized, '/value_object/'));
}

bool isRepositoryFilePath(String path) {
  return _containsSegment(path, '/lib/infrastructure/repositories/');
}

bool isServiceFilePath(String path) {
  return _containsSegment(path, '/lib/infrastructure/services/');
}

bool isDtoMapperFilePath(String path) {
  return _containsSegment(path, '/lib/infrastructure/dal/dto/mappers/');
}

bool isPresentationControllerFilePath(String path) {
  final normalized = normalizePath(path);
  return _containsSegment(normalized, '/lib/presentation/') &&
      _containsSegment(normalized, '/controllers/');
}

bool isPresentationWidgetControllerFilePath(String path) {
  final normalized = normalizePath(path);
  return isPresentationControllerFilePath(normalized) &&
      _containsSegment(normalized, '/widgets/');
}

String? widgetControllerOwnerRootPath(String path) {
  final normalized = normalizePath(path);
  if (!isPresentationWidgetControllerFilePath(normalized)) {
    return null;
  }

  const controllersMarker = '/controllers/';
  final markerIndex = normalized.lastIndexOf(controllersMarker);
  if (markerIndex == -1) {
    return null;
  }

  return normalized.substring(0, markerIndex);
}

bool isPathWithinRoot(String path, String rootPath) {
  final normalizedPath = normalizePath(path).replaceAll(RegExp(r'/+$'), '');
  final normalizedRoot = normalizePath(rootPath).replaceAll(RegExp(r'/+$'), '');

  return normalizedPath == normalizedRoot ||
      normalizedPath.startsWith('$normalizedRoot/');
}

bool isModularModuleFilePath(String path) {
  return _containsSegment(path, '/lib/application/router/modular_app/modules/');
}

bool isAllowedGlobalRegistrationFilePath(String path) {
  final normalized = normalizePath(path);

  return normalized.endsWith('/lib/main.dart') ||
      normalized.endsWith(
        '/lib/application/router/modular_app/module_settings.dart',
      ) ||
      normalized.endsWith(
        '/lib/infrastructure/repositories/app_data_repository.dart',
      );
}

bool isModuleSettingsFilePath(String path) {
  final normalized = normalizePath(path);
  return normalized.endsWith(
    '/lib/application/router/modular_app/module_settings.dart',
  );
}

bool isTenantCanonicalDomainEnforcementFilePath(String path) {
  final normalized = normalizePath(path);

  if (normalized.endsWith(
    '/lib/application/configurations/belluga_constants.dart',
  )) {
    return true;
  }

  final isInfrastructureNetworkingFile =
      _containsSegment(normalized, '/lib/infrastructure/repositories/') ||
      _containsSegment(normalized, '/lib/infrastructure/dal/dao/');
  if (!isInfrastructureNetworkingFile) {
    return false;
  }

  if (_containsSegment(normalized, '/mock_backend/')) {
    return false;
  }

  if (normalized.endsWith(
    '/lib/infrastructure/repositories/landlord_auth_repository.dart',
  )) {
    return false;
  }

  return true;
}

String? presentationRootKey(String path) {
  final normalized = normalizePath(path);
  const absoluteMarker = '/lib/presentation/';
  const relativeMarker = 'lib/presentation/';
  const packageMarker = 'package:';

  String? relative;
  final absoluteIndex = normalized.indexOf(absoluteMarker);
  if (absoluteIndex != -1) {
    relative = normalized.substring(absoluteIndex + absoluteMarker.length);
  } else if (normalized.startsWith(relativeMarker)) {
    relative = normalized.substring(relativeMarker.length);
  } else if (normalized.startsWith(packageMarker)) {
    final packageSeparatorIndex = normalized.indexOf('/');
    if (packageSeparatorIndex != -1) {
      final packageRelative = normalized.substring(packageSeparatorIndex + 1);
      if (packageRelative.startsWith('presentation/')) {
        relative = packageRelative.substring('presentation/'.length);
      } else if (packageRelative.startsWith(relativeMarker)) {
        relative = packageRelative.substring(relativeMarker.length);
      }
    }
  } else {
    const genericPresentationMarker = 'presentation/';
    final genericIndex = normalized.indexOf(genericPresentationMarker);
    if (genericIndex != -1) {
      relative = normalized.substring(
        genericIndex + genericPresentationMarker.length,
      );
    }
  }

  if (relative == null || relative.isEmpty) {
    return null;
  }

  final segments = relative.split('/');
  if (segments.length < 2) {
    return null;
  }

  return '${segments[0]}/${segments[1]}';
}

bool isSharedPresentationRootKey(String rootKey) {
  return rootKey.startsWith('shared/');
}
