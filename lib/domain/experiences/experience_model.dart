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
    List<ExperienceHighlightItemValue>? highlightItemValues,
    List<ExperienceTagValue>? tagValues,
    ExperienceOptionalTextValue? durationValue,
    ExperienceOptionalTextValue? priceLabelValue,
    ExperienceOptionalTextValue? meetingPointValue,
  })  : descriptionValue = descriptionValue ?? ExperienceDescriptionValue(),
        imageUrlValue = imageUrlValue ?? ExperienceImageUrlValue(),
        highlightItemValues = List<ExperienceHighlightItemValue>.unmodifiable(
          highlightItemValues ?? const <ExperienceHighlightItemValue>[],
        ),
        tagValues = List<ExperienceTagValue>.unmodifiable(
          tagValues ?? const <ExperienceTagValue>[],
        ),
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
  final List<ExperienceHighlightItemValue> highlightItemValues;
  final List<ExperienceTagValue> tagValues;
  final ExperienceOptionalTextValue durationValue;
  final ExperienceOptionalTextValue priceLabelValue;
  final ExperienceOptionalTextValue meetingPointValue;

  String get id => idValue.value;
  String get title => titleValue.value;
  String get category => categoryValue.value;
  String get providerName => providerNameValue.value;
  String get providerId => providerIdValue.value;
  String get description => descriptionValue.value;
  String? get imageUrl => imageUrlValue.nullableValue;
  List<ExperienceHighlightItemValue> get highlightItems =>
      List<ExperienceHighlightItemValue>.unmodifiable(highlightItemValues);
  List<ExperienceTagValue> get tags =>
      List<ExperienceTagValue>.unmodifiable(tagValues);
  String? get duration => durationValue.nullableValue;
  String? get priceLabel => priceLabelValue.nullableValue;
  String? get meetingPoint => meetingPointValue.nullableValue;
}
