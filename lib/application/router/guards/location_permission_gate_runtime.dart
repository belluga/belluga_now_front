class LocationPermissionGateRuntime {
  static bool _softLocationFallbackEntryArmed = false;

  static void armSoftLocationFallbackEntry() {
    _softLocationFallbackEntryArmed = true;
  }

  static bool consumeSoftLocationFallbackEntry() {
    final armed = _softLocationFallbackEntryArmed;
    _softLocationFallbackEntryArmed = false;
    return armed;
  }

  static void resetForTesting() {
    _softLocationFallbackEntryArmed = false;
  }
}
