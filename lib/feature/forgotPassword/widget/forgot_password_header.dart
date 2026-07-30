import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:flutter/material.dart';

class ForgotPasswordHeader extends StatelessWidget {
  final String title;
  final String subTitle;
  const ForgotPasswordHeader({
    super.key,
    required this.title,
    required this.subTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: context.bold.copyWith(fontSize: 16, color: kBlackColor),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Text(
            subTitle,
            textAlign: TextAlign.center,
            style: context.medium.copyWith(fontSize: 14, color: kDarkGreyColor),
          ),
        ),
      ],
    );
  }
}
