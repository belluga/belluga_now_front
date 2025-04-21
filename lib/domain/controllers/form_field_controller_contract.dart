import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:value_objects/domain/exceptions/value_exceptions.dart';
import 'package:value_objects/value_object.dart';

abstract class FormFieldControllerContract<T> {
  FormFieldControllerContract({String? initialValue}) {
    textController = TextEditingController(text: initialValue);
  }

  ValueObject<T> get valueObject;

  late TextEditingController textController;
  final errorStreamValue = StreamValue<String?>();

  String get text => textController.text;

  T get value => valueObject.value;

  String errorToString(ValueException error);

  String? validator(String? valueText) {
    late String? _errorMessage;

    try {
      valueObject.parse(valueText);
      return null;
    } on ValueException catch (e) {
      _errorMessage = errorToString(e);
    } catch (e) {
      _errorMessage = "Erro ao salvar";
    }

    errorStreamValue.addValue(_errorMessage);
    return _errorMessage;
  }

  void addValue(String value) {
    textController.text = value;
    valueObject.tryParse(text);
  }

  void addError(String errror) => errorStreamValue.addValue(errror);

  void cleanError() => errorStreamValue.addValue(null);

  void dispose() {
    textController.dispose();
    errorStreamValue.dispose();
  }
}
