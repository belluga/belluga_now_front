enum PromotionLeadMobilePlatform {
  ios,
  android;

  String get label =>
      this == PromotionLeadMobilePlatform.ios ? 'iOS' : 'Android';
}
