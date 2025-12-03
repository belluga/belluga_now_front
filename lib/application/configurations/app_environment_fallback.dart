import 'package:belluga_now/application/configurations/belluga_constants.dart';

Map<String, dynamic> get kLocalEnvironmentFallback => <String, dynamic>{
      'name': 'Fallback',
      'type': 'tenant',
      'main_domain': 'https://boilerplate.belluga.space',
      'domains': [],
      'app_domains': [],
      'theme_data_settings': {
        'brightness_default': 'dark',
        'primary_seed_color': '#4FA0E3',
        'secondary_seed_color': '#E80D5D',
      },
      'main_color': '#4FA0E3',
      'main_logo_light_url':
          'https://${BellugaConstants.landlordDomain}/light_logo.png',
      'main_logo_dark_url':
          'https://${BellugaConstants.landlordDomain}/dark_logo.png',
      'main_icon_light_url':
          'https://${BellugaConstants.landlordDomain}/light_icon.png',
      'main_icon_dark_url':
          'https://${BellugaConstants.landlordDomain}/dark_icon.png',
    };
