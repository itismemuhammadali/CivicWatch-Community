import 'package:flutter/material.dart';

extension Context on BuildContext {
  void closeKeyboard() => FocusScope.of(this).unfocus();

  double get topPadding => MediaQuery.paddingOf(this).top;
  double get bottomPadding => MediaQuery.paddingOf(this).bottom;
}

extension ThemeContext on BuildContext {
  TextTheme get textTheme => Theme.of(this).textTheme;

  ThemeData get theme => Theme.of(this);

  Size get sizes => MediaQuery.sizeOf(this);

  TextStyle get _baseTextStyle => textTheme.bodyMedium!;

  TextStyle get light => _baseTextStyle.copyWith(fontWeight: FontWeight.w300);

  TextStyle get normal => _baseTextStyle.copyWith(fontWeight: FontWeight.w400);

  TextStyle get medium => _baseTextStyle.copyWith(fontWeight: FontWeight.w500);

  TextStyle get semiBold =>
      _baseTextStyle.copyWith(fontWeight: FontWeight.w600);

  TextStyle get bold => _baseTextStyle.copyWith(fontWeight: FontWeight.w700);

  TextStyle get black => _baseTextStyle.copyWith(fontWeight: FontWeight.w900);
}

extension SizeConfig on BuildContext {
  double get height => MediaQuery.sizeOf(this).height;
  double get width => MediaQuery.sizeOf(this).width;
  bool get isSmallScreen => height <= 688;
  bool get isMediumScreen => height > 688 && height <= 932;
  bool get isLargeScreen => height > 930;
}