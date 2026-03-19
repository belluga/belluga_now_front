enum LocationTrackingMode {
  /// High accuracy, foreground usage (e.g., map open).
  mapForeground,

  /// Low accuracy / lower update rate (e.g., background-ish UI needs).
  lowPower,
}
