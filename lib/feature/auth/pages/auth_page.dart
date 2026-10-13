import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/utils/assets.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/feature/auth/widget/signin_view.dart';
import 'package:cctv_app/feature/auth/widget/signup_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = true;

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: Scaffold(
        backgroundColor: kWhiteColor,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 40.0,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(Assets.pngAppLogoImage, width: 100, height: 100),
                        Space.vertical(24),
                        isLogin ? const SigninView() : const SignupView(),
                        Space.vertical(20),
                        isLogin
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    "New User?",
                                    style: context.medium.copyWith(
                                      color: kDarkGreyColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                  CupertinoButton(
                                    onPressed: () {
                                      setState(() {
                                        isLogin = false;
                                      });
                                    },
                                    padding: EdgeInsets.zero,
                                    child: Text(
                                      " Sign Up",
                                      style: context.semiBold.copyWith(
                                        color: kBlackColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Already have an account?",
                                    style: context.medium.copyWith(
                                      color: kDarkGreyColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                  CupertinoButton(
                                    onPressed: () {
                                      setState(() {
                                        isLogin = true;
                                      });
                                    },
                                    padding: EdgeInsets.zero,
                                    child: Text(
                                      " Log in",
                                      style: context.semiBold.copyWith(
                                        color: kBlackColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
