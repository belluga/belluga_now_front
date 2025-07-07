import 'package:flutter/material.dart';

class LessonTile extends StatefulWidget {
  const LessonTile({super.key});

  @override
  State<LessonTile> createState() => _LessonTileState();
}

class _LessonTileState extends State<LessonTile> {
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
