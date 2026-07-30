import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:flutter/material.dart';

class RegionContainer extends StatelessWidget {
  final String flagAsset;
  final String countryName;
  final String views;

  const RegionContainer({
    super.key,
    required this.flagAsset,
    required this.countryName,
    required this.views,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Image.asset(flagAsset, width: 28, height: 28),
                Space.horizontal(10),
                Text(
                  countryName,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            Text(
              views,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: kDarkGreyColor,
              ),
            ),
          ],
        ),
        Divider(color: kDarkGreyColor.withValues(alpha:0.2), thickness: 1),
      ],
    );
  }
}
