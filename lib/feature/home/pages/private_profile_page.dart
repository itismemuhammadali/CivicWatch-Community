import 'package:cctv_app/core/components/primary_button.dart';
import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/utils/assets.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:flutter/material.dart';

class PrivateProfilePage extends StatelessWidget {
  const PrivateProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhiteColor,
      appBar: AppBar(
        backgroundColor: kWhiteColor,
        centerTitle: true,
        title: Text("Profile", style: context.bold.copyWith(fontSize: 18)),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 10, left: 16.0, right: 16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage(Assets.pngUser1Image),
                ),
                Space.horizontal(16),
                Column(
                  children: [
                    Text(
                      "Edlie Lake",
                      style: context.bold.copyWith(fontSize: 18),
                    ),
                    Text(
                      "Offline",
                      style: context.normal.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            Space.vertical(20),
            PrimaryButton(
              text: "Profile is private",
              buttonColor: kGreyColor,
              textColor: kBlackColor,
              height: 44,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
