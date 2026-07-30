import 'package:cctv_app/core/components/custom_otp_textfield_widget.dart';
import 'package:cctv_app/core/components/primary_button.dart';
import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/feature/forgotPassword/pages/new_password.dart';
import 'package:cctv_app/feature/forgotPassword/widget/forgot_password_header.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class EmailVerifcation extends StatefulWidget {
  const EmailVerifcation({super.key});

  @override
  State<EmailVerifcation> createState() => _EmailVerifcationState();
}

class _EmailVerifcationState extends State<EmailVerifcation> {
  String otpCode = '';
  bool isOtpEmpty = false;

  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Widget buildOtpField(BuildContext context, int index) {
    return CustomOtpTextfieldWidget(
      controller: _controllers[index],
      focusNode: _focusNodes[index],
      onChanged: (value) {
        if (value.isNotEmpty && index < 3) {
          FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
        } else if (value.isEmpty && index > 0) {
          FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
        }
        final otp = _controllers.map((controller) => controller.text).join();
        setState(() {
          otpCode = otp;
        });
      },
      onPaste: (pastedText) {
        // _handleOtpPaste(context, pastedText, index);
      },
      fieldColor: kLightGreyColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhiteColor,
      appBar: AppBar(
        title: const Text(
          "Email Verification",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: kWhiteColor,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Space.vertical(50),
              ForgotPasswordHeader(
                title: "Get Your Code",
                subTitle:
                    "Please enter the 4 digit code that was sent to your email address",
              ),
              Space.vertical(20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  final spacing = 12.0;
                  final boxCount = 4;
                  double totalSpacing = spacing * (boxCount - 1);
                  double otpBoxSize = (screenWidth - totalSpacing) / boxCount;
                  otpBoxSize = otpBoxSize.clamp(40, 50);
                  return Wrap(
                    alignment: WrapAlignment.center,
                    spacing: spacing,
                    runSpacing: 12,
                    children: List.generate(4, (index) {
                      return SizedBox(
                        width: otpBoxSize,
                        height: otpBoxSize,
                        child: buildOtpField(context, index),
                      );
                    }),
                  );
                },
              ),
              Space.vertical(16),
              if (otpCode.length != 4 && isOtpEmpty)
                Text(
                  "Please enter 4 digit code",
                  style: context.medium.copyWith(
                    color: kRedColor,
                    fontSize: 14,
                  ),
                ),
              Space.vertical(20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "If you don't receive code",
                    style: context.medium.copyWith(
                      color: kDarkGreyColor,
                      fontSize: 14,
                    ),
                  ),
                  CupertinoButton(
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    child: Text(
                      " Resend",
                      style: context.semiBold.copyWith(
                        color: kPrimaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              Space.vertical(30),
              PrimaryButton(
                text: "Verify and proceed",
                isMainAxisSizeMin: true,
                padding: EdgeInsets.symmetric(horizontal: 50),
                onPressed: otpCode.length == 4
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NewPassword(),
                          ),
                        );
                      }
                    : () {
                        setState(() {
                          isOtpEmpty = true;
                        });
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
