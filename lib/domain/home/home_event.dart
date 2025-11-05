import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/home/home_event_dto.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';

class HomeEvent {
  HomeEvent({
    required this.slug,
    required this.titleValue,
    required this.imageUriValue,
    required this.startDateTimeValue,
    required this.locationValue,
    required this.artistValue,
  });

  final String slug;
  final TitleValue titleValue;
  final ThumbUriValue imageUriValue;
  final DateTimeValue startDateTimeValue;
  final DescriptionValue locationValue;
  final TitleValue artistValue;

  factory HomeEvent.fromDTO(HomeEventDTO dto) {
    final title = TitleValue()..parse(dto.title);
    final imageUri = ThumbUriValue(
      defaultValue: Uri.parse(dto.imageUrl),
      isRequired: true,
    )..parse(dto.imageUrl);
    final startDate = DateTimeValue(isRequired: true)
      ..parse(dto.startDateTime.toIso8601String());
    final location = DescriptionValue()..parse(dto.location);
    final artist = TitleValue()..parse(dto.artist);

    return HomeEvent(
      slug: dto.id ?? _slugify(dto.title),
      titleValue: title,
      imageUriValue: imageUri,
      startDateTimeValue: startDate,
      locationValue: location,
      artistValue: artist,
    );
  }

  String get title => titleValue.value;
  Uri get imageUri => imageUriValue.value;
  DateTime get startDateTime {
    final date = startDateTimeValue.value;
    assert(date != null, 'startDateTime should not be null');
    return date!;
  }

  String get location => locationValue.value;
  String get artist => artistValue.value;

  static String _slugify(String value) {
    final slug = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final cleaned = slug.replaceAll(RegExp(r'-{2,}'), '-');
    return cleaned.replaceAll(RegExp(r'^-+|-+$'), '');
  }
}
