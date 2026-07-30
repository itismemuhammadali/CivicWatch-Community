import 'package:cctv_app/core/components/custom_textfield.dart';
import 'package:cctv_app/core/components/primary_button.dart';
import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/core/utils/validators.dart';
import 'package:cctv_app/feature/forgotPassword/pages/email_verifcation.dart';
import 'package:cctv_app/feature/forgotPassword/widget/forgot_password_header.dart';
import 'package:flutter/material.dart';

class ForgotPasword extends StatefulWidget {
  const ForgotPasword({super.key});

  @override
  State<ForgotPasword> createState() => _ForgotPaswordState();
}

class _ForgotPaswordState extends State<ForgotPasword> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhiteColor,
      appBar: AppBar(
        title: const Text(
          "Forgot Password",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
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
                  title: "Mail Address Here",
                  subTitle:
                      "Enter the email address associated with your account.",
                ),
                Space.vertical(20),
                CustomTextField(
                  hintText: "Email",
                  controller: emailController,
                  hintTextColor: kDarkGreyColor,
                  validator: (value) {
                    return Validators.email(value);
                  },
                  suffix: const Icon(
                    Icons.email_outlined,
                    color: kDarkGreyColor,
                  ),
                ),
                Space.vertical(50),
                PrimaryButton(
                  text: "Recover password",
                  isMainAxisSizeMin: true,
                  padding: EdgeInsets.symmetric(horizontal: 50),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EmailVerifcation(),
                        ),
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
