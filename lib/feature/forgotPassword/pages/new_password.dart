import 'package:cctv_app/core/components/custom_textfield.dart';
import 'package:cctv_app/core/components/primary_button.dart';
import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/core/utils/validators.dart';
import 'package:cctv_app/feature/auth/pages/auth_page.dart';
import 'package:cctv_app/feature/forgotPassword/widget/forgot_password_header.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NewPassword extends StatefulWidget {
  const NewPassword({super.key});

  @override
  State<NewPassword> createState() => _NewPasswordState();
}

class _NewPasswordState extends State<NewPassword> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhiteColor,
      appBar: AppBar(
        title: const Text(
          "Create new password",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: kWhiteColor,
        centerTitle: true,
      ),
      body: Form(
        key: formKey,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Space.vertical(50),
                ForgotPasswordHeader(
                  title: "Enter New Password",
                  subTitle:
                      "Your new password must be different from previously used password.",
                ),
                Space.vertical(20),
                CustomTextField(
                  hintText: "Password",
                  controller: passwordController,
                  obscureText: obscurePassword,
                  hintTextColor: kDarkGreyColor,
                  validator: (value) {
                    return Validators.password(value);
                  },
                  suffix: CupertinoButton(
                    child: Icon(
                      obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.remove_red_eye_outlined,
                      color: kDarkGreyColor,
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                ),
                Space.vertical(16),
                CustomTextField(
                  hintText: "Confirm Password",
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword,
                  hintTextColor: kDarkGreyColor,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Required";
                    }
                    if (passwordController.text !=
                        confirmPasswordController.text) {
                      return "Passwords do not match";
                    }
                    return null;
                  },
                  suffix: CupertinoButton(
                    child: Icon(
                      obscureConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.remove_red_eye_outlined,
                      color: kDarkGreyColor,
                    ),
                    onPressed: () {
                      setState(() {
                        obscureConfirmPassword = !obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                Space.vertical(30),
                PrimaryButton(
                  text: "Continue",
                  isMainAxisSizeMin: true,
                  padding: EdgeInsets.symmetric(horizontal: 50),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AuthPage()),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
