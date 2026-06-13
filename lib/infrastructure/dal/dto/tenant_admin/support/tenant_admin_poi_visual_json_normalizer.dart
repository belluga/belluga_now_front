Object? tenantAdminResolvePoiVisualRaw({
  required Object? visualRaw,
  required Object? typeAssetUrl,
}) {
  if (visualRaw is! Map) {
    return visualRaw;
  }

  final visualMap = Map<String, dynamic>.from(visualRaw);
  if (_readTrimmedString(visualMap['image_url']) != null) {
    return visualMap;
  }

  final fallbackTypeAssetUrl = _readTrimmedString(typeAssetUrl);
  if (fallbackTypeAssetUrl != null) {
    visualMap['image_url'] = fallbackTypeAssetUrl;
  }
  return visualMap;
}

String? _readTrimmedString(Object? raw) {
  final value = raw?.toString().trim();
  if (value == null || value.isEmpty) {
    return null;
  }
  return value;
}
