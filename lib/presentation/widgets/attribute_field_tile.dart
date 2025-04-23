import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/attribute/attribute_model.dart';

class AttributeFieldTile<T> extends StatelessWidget {
  final AttributeModel<T> attribute;

  const AttributeFieldTile({
    super.key,
    required this.attribute,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 30, 0, 0),
      child: ListTile(
        tileColor: const Color(0x00ffffff),
        title: Text(
          attribute.label,
          style: const TextStyle(
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.normal,
            fontSize: 14,
            color: Color(0xff424141),
          ),
          textAlign: TextAlign.start,
        ),
        subtitle: Text(
          attribute.text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.normal,
            fontSize: 16,
            color: Color(0xff000000),
          ),
          textAlign: TextAlign.start,
        ),
        dense: true,
        contentPadding: const EdgeInsets.all(0),
        selected: false,
        selectedTileColor: const Color(0x42000000),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        leading: Icon(attribute.icons),
        trailing: attribute.isEditable
            ? const Icon(Icons.edit, color: Color(0xff79797c), size: 22)
            : null,
      ),
    );
  }
}
