import 'package:flutter/widgets.dart';

class Space extends StatelessWidget {
  const Space.horizontal(double value, {super.key}) : width = value, height = 0;

  const Space.vertical(double value, {super.key}) : width = 0, height = value;

  final double height, width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height, width: width);
  }
}