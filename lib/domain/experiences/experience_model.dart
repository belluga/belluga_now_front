import 'package:belluga_now/domain/experiences/value_objects/experience_fields.dart';

class ExperienceModel {
  ExperienceModel({
    required this.idValue,
    required this.titleValue,
    required this.categoryValue,
    required this.providerNameValue,
    required this.providerIdValue,
    ExperienceDescriptionValue? descriptionValue,
    ExperienceImageUrlValue? imageUrlValue,
    ExperienceStringListValue? highlightItemValues,
    ExperienceStringListValue? tagValues,
    ExperienceOptionalTextValue? durationValue,
    ExperienceOptionalTextValue? priceLabelValue,
    ExperienceOptionalTextValue? meetingPointValue,
  })  : descriptionValue = descriptionValue ?? ExperienceDescriptionValue(),
        imageUrlValue = imageUrlValue ?? ExperienceImageUrlValue(),
        highlightItemValues = highlightItemValues ?? ExperienceStringListValue(),
        tagValues = tagValues ?? ExperienceStringListValue(),
        durationValue = durationValue ?? ExperienceOptionalTextValue(),
        priceLabelValue = priceLabelValue ?? ExperienceOptionalTextValue(),
        meetingPointValue = meetingPointValue ?? ExperienceOptionalTextValue();

  final ExperienceIdValue idValue;
  final ExperienceTitleValue titleValue;
  final ExperienceCategoryValue categoryValue;
  final ExperienceProviderNameValue providerNameValue;
  final ExperienceProviderIdValue providerIdValue;
  final ExperienceDescriptionValue descriptionValue;
  final ExperienceImageUrlValue imageUrlValue;
  final ExperienceStringListValue highlightItemValues;
  final ExperienceStringListValue tagValues;
  final ExperienceOptionalTextValue durationValue;
  final ExperienceOptionalTextValue priceLabelValue;
  final ExperienceOptionalTextValue meetingPointValue;

  String get id => idValue.value;
  String get title => titleValue.value;
  String get category => categoryValue.value;
  String get providerName => providerNameValue.value;
  String get providerId => providerIdValue.value;
  String get description => descriptionValue.value;
  String? get imageUrl => imageUrlValue.value;
  List<String> get highlightItems => highlightItemValues.value;
  List<String> get tags => tagValues.value;
  String? get duration => durationValue.value;
  String? get priceLabel => priceLabelValue.value;
  String? get meetingPoint => meetingPointValue.value;
}
