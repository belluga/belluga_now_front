class LocationStream {
  LocationStream get stream => this;

  void listen(void Function(Object?) listener) {}
}

class UserLocationRepository {
  LocationStream get userLocationStreamValue => LocationStream();

  LocationStream get lastKnownLocationStreamValue => LocationStream();
}

class LocationOriginDirectStreamSubscriptionCase {
  LocationOriginDirectStreamSubscriptionCase(this.repository);

  final UserLocationRepository repository;

  void bind() {
    // expect_lint: location_origin_canonical_stream_subscription_required
    repository.userLocationStreamValue.stream.listen((_) {});
    // expect_lint: location_origin_canonical_stream_subscription_required
    repository.lastKnownLocationStreamValue.stream.listen((_) {});
  }
}
