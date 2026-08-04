import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 69.1,
        child: DropdownButtonFormField<String>(
          isExpanded: true,
          value: 'September',
          items: [
            DropdownMenuItem(value: 'September', child: Text('September'))
          ],
          onChanged: (v) {},
        ),
      ),
    ),
  ));
}
