typedef WebBootstrapResolver<T> = Future<T> Function();

final class WebBootstrapFallbackResolver<T> {
  const WebBootstrapFallbackResolver({
    required this.bootstrapResolver,
    required this.fallbackResolver,
  });

  final WebBootstrapResolver<T> bootstrapResolver;
  final WebBootstrapResolver<T> fallbackResolver;

  Future<T> resolve() async {
    try {
      return await bootstrapResolver();
    } catch (bootstrapError) {
      try {
        return await fallbackResolver();
      } catch (fallbackError, fallbackStackTrace) {
        Error.throwWithStackTrace(
          Exception(
            'Web bootstrap resolution failed. '
            'bootstrap=$bootstrapError '
            'fallback=$fallbackError',
          ),
          fallbackStackTrace,
        );
      }
    }
  }
}
