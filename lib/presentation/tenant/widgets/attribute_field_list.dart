import 'package:flutter/material.dart';
import 'package:belluga_now/domain/attribute/attribute_model.dart';
import 'package:belluga_now/presentation/tenant/widgets/attribute_field_tile.dart';

class AttributeFieldList extends StatelessWidget {
  final List<AttributeModel> list;

  const AttributeFieldList({super.key, required this.list});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemBuilder: (_, i) => AttributeFieldTile(attribute: list[i]),
      separatorBuilder: (_, i) => const Divider(
        color: Color(0xffdddddd),
        height: 20,
        thickness: 0,
        indent: 50,
        endIndent: 0,
      ),
      itemCount: list.length,
    );
  }
}
