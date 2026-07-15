import 'package:belluga_contact_channels/belluga_contact_channels.dart';
import 'package:get_it/get_it.dart';

class FirstPartyContactChannelDomainParameterCase {
  const FirstPartyContactChannelDomainParameterCase();

  void acceptsChannel(
    // expect_no_lint: domain_primitive_field_forbidden
    BellugaContactChannel channel,
  ) {}

  void acceptsChannelCollection(
    // expect_no_lint: domain_primitive_field_forbidden
    List<BellugaContactChannel> channels,
  ) {}

  void rejectsUnregisteredExternalType(
    // expect_lint: domain_primitive_field_forbidden
    GetIt externalDependency,
  ) {}
}
