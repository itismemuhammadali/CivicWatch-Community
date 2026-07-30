import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:flutter/material.dart';

import 'space.dart';

class PlainSelectionWidget extends StatelessWidget {
  const PlainSelectionWidget({
    super.key,
    required this.onChange,
    required this.isSelected,
    required this.title,
    required this.subTitle,
    this.textFontWeight = FontWeight.w500,
    this.textFontSize = 14,
    this.bottomPadding = 12,
  });
  final VoidCallback onChange;
  final bool isSelected;
  final String title;
  final String subTitle;
  final FontWeight textFontWeight;
  final double textFontSize;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChange,
      child: Container(
        color: kTransparentColor,
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Row(
          children: [
            // ✅ simple checkbox (without gradient or animation)
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                border: Border.all(color: kDarkGreyColor, width: 2),
                borderRadius: BorderRadius.circular(4),
                color: isSelected ? kPrimaryColor : kTransparentColor,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : null,
            ),
            Space.horizontal(10),

            Flexible(
              child: Align(
                alignment: Alignment.centerLeft,
                child: RichText(
                  text: TextSpan(
                    text: '$title ',
                    style: context.semiBold.copyWith(
                      fontSize: textFontSize,
                      fontWeight: textFontWeight,
                      decorationColor: kDarkGreyColor,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: subTitle,
                        style: context.semiBold.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: kDarkGreyColor,
                          decorationColor: kDarkGreyColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
