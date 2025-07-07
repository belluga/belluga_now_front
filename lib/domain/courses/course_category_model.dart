import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/courses/value_objects/category_name.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/courses/value_objects/color_value.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/courses/value_objects/slug_value.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/course/category_dto.dart';
import 'package:value_objects/domain/value_objects/mongo_id_value.dart';

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
