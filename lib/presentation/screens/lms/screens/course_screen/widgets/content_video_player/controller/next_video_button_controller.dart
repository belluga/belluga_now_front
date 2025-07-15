class NextVideoButtonController {
  double getButtonOpacity(double videoPercentage) {
    if (videoPercentage >= 0.90) {
      return 0.8;
    } else if (videoPercentage >= 1) {
      return 1;
    } else {
      return 0.0;
    }
  }
}
