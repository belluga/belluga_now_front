import 'package:flutter/material.dart';

class CourseItemTile extends StatefulWidget {
  const CourseItemTile({super.key});

  @override
  State<CourseItemTile> createState() => _CourseItemTileState();
}

class _CourseItemTileState extends State<CourseItemTile> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [Text("adfasdf asdadas"), Text("afsfdasfas afsdaf")],
            ),
          ),
          Checkbox(value: false, onChanged: (value) {}),
        ],
      ),
    );
  }
}
