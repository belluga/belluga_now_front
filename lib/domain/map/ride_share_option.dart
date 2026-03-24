import 'package:belluga_now/domain/map/ride_share_provider.dart';
import 'package:belluga_now/domain/map/value_objects/ride_share_label_value.dart';
import 'package:belluga_now/domain/map/value_objects/ride_share_uri_value.dart';

class RideShareOption {
  const RideShareOption({
    required this.provider,
    required this.labelValue,
    required this.uriValues,
  });

  final RideShareProvider provider;
  final RideShareLabelValue labelValue;
  final List<RideShareUriValue> uriValues;

  String get label => labelValue.value;

  List<Uri> get uris => uriValues.map((value) => value.value).toList();
}
