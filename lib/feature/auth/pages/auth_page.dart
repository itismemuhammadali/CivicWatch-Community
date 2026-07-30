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
  int selectedRoleIndex = 2; // 0: Super Admin, 1: Admin, 2: User (default User)

  final List<String> _roleLabels = [
    'Super Admin',
    'Admin',
    'User',
  ];

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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Space.vertical(20),
                  Image.asset(Assets.pngAppLogoImage, width: 100, height: 100),
                  Space.vertical(30),
                  // 3 Role selector buttons
                  Container(
                    decoration: BoxDecoration(
                      color: kWhiteColor,
                      border: Border.all(color: kGreyColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Row(
                      children: List.generate(_roleLabels.length, (index) {
                        final isSelected = selectedRoleIndex == index;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedRoleIndex = index;
                              });
                            },
                            child: Container(
                              margin: EdgeInsets.only(right: index < _roleLabels.length - 1 ? 6 : 0),
                              decoration: BoxDecoration(
                                color: isSelected ? kPrimaryColor : kWhiteColor,
                                border: Border.all(
                                  color: isSelected ? kTransparentColor : kGreyColor.withValues(alpha: 0.5),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Text(
                                _roleLabels[index],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.medium.copyWith(
                                  fontSize: 13,
                                  color: isSelected ? kWhiteColor : kDarkGreyColor,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  Space.vertical(30),
                  selectedRoleIndex != 2
                      ? SigninView(selectedRoleIndex: selectedRoleIndex)
                      : isLogin
                          ? SigninView(selectedRoleIndex: 2)
                          : const SignupView(),
                  Space.vertical(20),
                  selectedRoleIndex != 2
                      ? const SizedBox()
                      : isLogin
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
                  Space.vertical(20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
