import 'package:flutter/material.dart';
import 'package:belluga_now/domain/courses/value_objects/category_name.dart';
import 'package:belluga_now/domain/value_objects/color_value.dart';
import 'package:belluga_now/domain/courses/value_objects/slug_value.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/course/category_dto.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

class CourseCategoryModel {
  MongoIDValue id;
  CategoryNameValue name;
  SlugValue slug;
  ColorValue color;

  CourseCategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.color,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is CourseCategoryModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  factory CourseCategoryModel.fromDto(CategoryDTO dto) {
    final _id = MongoIDValue()..parse(dto.id);
    final _name = CategoryNameValue()..parse(dto.name);
    final _slug = SlugValue()..parse(dto.slug);
    final _color = ColorValue(defaultValue: Colors.tealAccent)
      ..tryParse(dto.colorHex);

    return CourseCategoryModel(
      id: _id,
      name: _name,
      slug: _slug,
      color: _color,
    );
  }
}
