import 'package:cctv_app/core/components/primary_button.dart';
import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/utils/assets.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomProfilePost extends StatelessWidget {
  const CustomProfilePost({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kGreyColor),
      ),
      padding: EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              Assets.pngHighlight1Image,
              width: double.infinity,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
          Space.vertical(6),
          Text("Food", style: context.bold.copyWith(fontSize: 14)),
          Space.vertical(4),
          Text(
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
            style: context.normal.copyWith(
              overflow: TextOverflow.ellipsis,
              fontSize: 12,
              color: kDarkGreyColor,
            ),
          ),
          Space.vertical(6),
          Align(
            alignment: AlignmentGeometry.centerRight,
            child: Text(
              "Apr 30, 10:27 am",
              style: context.normal.copyWith(
                overflow: TextOverflow.ellipsis,
                fontSize: 12,
                color: kDarkGreyColor,
              ),
            ),
          ),
          Space.vertical(6),
          PrimaryButton(
            height: 45,
            text: "View Post",
            padding: EdgeInsets.symmetric(horizontal: 2),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
