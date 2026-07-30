import 'package:cctv_app/core/components/primary_button.dart';
import 'package:cctv_app/core/utils/assets.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/feature/auth/pages/auth_page.dart';
import 'package:flutter/material.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhiteColor,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PrimaryButton(
                text: "",
                onPressed: () {},
                buttonColor: kTransparentColor,
              ),
              Image.asset(Assets.pngAppLogoImage, width: 250, height: 250),
              PrimaryButton(
                text: "Get start",
                textFontWeight: FontWeight.bold,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AuthPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
