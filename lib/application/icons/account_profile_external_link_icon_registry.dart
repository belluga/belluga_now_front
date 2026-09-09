import 'package:belluga_now/domain/partners/account_profile_external_link.dart';
import 'package:flutter/material.dart';
import 'package:simple_icons/simple_icons.dart';

abstract final class AccountProfileExternalLinkIconRegistry {
  static IconData iconFor(AccountProfileExternalLinkType type) =>
      switch (type) {
        AccountProfileExternalLinkType.instagram => SimpleIcons.instagram,
        AccountProfileExternalLinkType.facebook => SimpleIcons.facebook,
        AccountProfileExternalLinkType.youtube => SimpleIcons.youtube,
        AccountProfileExternalLinkType.tiktok => SimpleIcons.tiktok,
        AccountProfileExternalLinkType.spotify => SimpleIcons.spotify,
        AccountProfileExternalLinkType.website => Icons.language_outlined,
      };
}
