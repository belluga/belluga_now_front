import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/controllers/form_field_controller_contract.dart';
import 'package:stream_value/core/stream_value_builder.dart';

abstract class FormFieldBelluga extends StatelessWidget {
  const FormFieldBelluga({
    super.key,
    required this.formFieldController,
    this.isEnabled = true,
  });

  final FormFieldControllerContract formFieldController;
  final bool isEnabled;

  String get label;
  String get hint;
  TextInputType get inputType;
  bool get obscureText => false;
  TextCapitalization get textCapitalization => TextCapitalization.none;

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<String?>(
      streamValue: formFieldController.errorStreamValue,
      builder: (context, errorText) {
        return TextFormField(
          controller: formFieldController.textController,
          enabled: isEnabled,
          keyboardType: inputType,
          obscureText: obscureText,
          textCapitalization: textCapitalization,
          onChanged: (_) => formFieldController.cleanError(),
          validator: formFieldController.validator,
          decoration: InputDecoration(
            suffixIcon: Icon(Icons.clear),
            errorText: errorText,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            labelText: label,
            hintText: hint,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF5C2D91), width: 2),
            ),
          ),
        );
      },
    );
  }
}
