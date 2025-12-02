import 'package:belluga_now/domain/map/ride_share_provider.dart';

class RideShareOption {
  const RideShareOption({
    required this.provider,
    required this.label,
    required this.uris,
  });

  final RideShareProvider provider;
  final String label;
  final List<Uri> uris;
}
