import 'package:flutter/material.dart';

class AttributeModel<T> {
  AttributeModel({
    required this.icons,
    required this.label,
    required this.value,
    this.hint,
    this.isEditable = true,
  });

  final IconData icons;
  final String label;
  final String? hint;
  final T value;
  final bool isEditable;

  String get text {

    final String _text = value != null ? value.toString() : hint ?? "";
    return _text;
  }
}
