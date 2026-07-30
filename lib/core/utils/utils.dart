import 'package:flutter/material.dart';

ColorFilter colorFilter({required Color color}) {
  return ColorFilter.mode(color, BlendMode.srcIn);
}