import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/core/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ProfileTile extends StatelessWidget {
  final String text;
  final String? icon;
  final IconData? iconData;
  final VoidCallback onTap;
  const ProfileTile({
    super.key,
    required this.text,
    this.icon,
    this.iconData,
    required this.onTap,
  }) : assert(icon != null || iconData != null);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: kTransparentColor),
        child: Column(
          children: [
            Row(
              children: [
                if (icon != null)
                  SvgPicture.asset(
                    icon!,
                    colorFilter: colorFilter(color: kPrimaryColor),
                  )
                else
                  Icon(iconData, color: kPrimaryColor, size: 26),
                Space.horizontal(20),
                Text(text, style: context.normal.copyWith(fontSize: 16)),
              ],
            ),
            Space.vertical(6),
            Divider(color: kGreyColor, thickness: 1),
          ],
        ),
      ),
    );
  }
}
