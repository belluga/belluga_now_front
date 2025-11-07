class FavoriteBadgeValue {
  FavoriteBadgeValue({
    required this.codePoint,
    this.fontFamily,
    this.fontPackage,
  }) : assert(codePoint > 0, 'badge code point must be positive');

  final int codePoint;
  final String? fontFamily;
  final String? fontPackage;
}
