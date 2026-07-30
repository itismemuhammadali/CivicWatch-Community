import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:flutter/material.dart';

import '../../../../core/extensions/context.dart';

class CustomMenuButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget icon;
  final String title;
  final Color? iconColor;
  final Color? textColor;
  final double? iconSize;
  const CustomMenuButton({
    super.key,
    required this.onTap,
    required this.icon,
    required this.title,
    this.iconColor,
    this.textColor,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            title,
            style: context.textTheme.titleMedium!.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor ?? kBlackColor,
            ),
          ),
          Space.horizontal(20),
          icon,
        ],
      ),
    );
  }
}
