import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/utils/app_constants.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.hintText,
    this.labelText,
    this.onChanged,
    this.onSubmitted,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
    this.prefix,
    this.textAlign = TextAlign.start,
    this.width,
    this.maxLength,
    this.maxLine = 1,
    this.focusNode,
    this.textInputAction,
    this.inputFormatters,
    this.onEditComplete,
    this.validator,
    this.is400 = false,
    this.fieldColor,
    this.topPadding = 20,
    this.bottomPadding = 20,
    this.showBorder = true,
    this.hintTextColor,
    this.is500 = false,
    this.inputFontSize = 16,
    this.inputFontWeight = FontWeight.w400,
    this.inputHeight = 1,
    this.hintTextHeight,
    this.cursorHeight,
    this.readOnly = false,
    this.enabled = true,
    this.minLines,
    this.onTap,
    this.textCapitalization,
    this.autoFocus = false,
    this.viewCustomCounter = false,
    this.onTapOutside,
    this.textColor,
    this.textStyle,
    this.hintTextStyle,
    this.cursorColor = kBlackColor,
    this.borderRadius = 8,
    this.suffixText,
  });
  final String hintText;
  final String? labelText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText, is400, is500;
  final Widget? suffix, prefix;
  final TextAlign textAlign;
  final double? width;
  final int? maxLength;
  final int maxLine;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final Function(String)? onChanged, onSubmitted;
  final VoidCallback? onEditComplete;
  final String? Function(String?)? validator;
  final Color? fieldColor;
  final double topPadding, bottomPadding;
  final bool showBorder;
  final Color? hintTextColor, textColor;
  final double inputFontSize, borderRadius;
  final FontWeight inputFontWeight;
  final double? inputHeight;
  final double? cursorHeight;
  final double? hintTextHeight;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<PointerDownEvent>? onTapOutside;
  final bool? enabled;
  final TextCapitalization? textCapitalization;
  final int? minLines;
  final bool autoFocus, viewCustomCounter;
  final TextStyle? textStyle, hintTextStyle;
  final Color cursorColor;
  final String? suffixText;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        TextFormField(
          cursorHeight: cursorHeight,
          textCapitalization: textCapitalization ?? TextCapitalization.none,
          enabled: enabled,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          readOnly: readOnly,
          onTap: onTap,
          autofocus: autoFocus,
          onTapOutside:
              onTapOutside ??
              (_) => FocusManager.instance.primaryFocus?.unfocus(),
          focusNode: focusNode,
          maxLength: maxLength,
          minLines: minLines,
          textAlign: textAlign,
          obscureText: obscureText,
          keyboardType: keyboardType,
          controller: controller,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          onEditingComplete: onEditComplete,
          cursorColor: cursorColor,
          style:
              textStyle ??
              TextStyle(
                fontFamily: kPrimaryFontFamily,
                fontSize: inputFontSize,
                fontWeight: inputFontWeight,
                color: textColor ?? kBlackColor,
              ),
          maxLines: maxLine,
          decoration: InputDecoration(
            suffixText: suffixText,
            prefixIcon: prefix,
            counterText: '',
            suffixIcon: suffix,
            contentPadding: EdgeInsets.only(
              right: 16,
              left: 16,
              top: topPadding,
              bottom: bottomPadding,
            ),
            labelText: labelText,
            labelStyle: TextStyle(
              fontFamily: kPrimaryFontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: kDarkGreyColor,
            ),
            floatingLabelBehavior: labelText != null
                ? FloatingLabelBehavior.always
                : FloatingLabelBehavior.never,
            hintStyle:
                hintTextStyle ??
                TextStyle(
                  fontFamily: kPrimaryFontFamily,
                  fontSize: inputFontSize,
                  fontWeight: FontWeight.w500,
                  color: hintTextColor,
                ),
            hintText: hintText,
            filled: true,
            fillColor: fieldColor ?? kWhiteColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                color: showBorder ? kGreyColor : kTransparentColor,
                width: 2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                color: showBorder ? kGreyColor : kTransparentColor,
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                color: showBorder ? kGreyColor : kTransparentColor,
                width: 2,
              ),
            ),
          ),
          errorBuilder: (c, val) {
            if (val.isEmpty) {
              return const SizedBox.shrink();
            }
            return Align(
              alignment: Alignment.centerRight,
              child: Text(
                val,
                style: context.normal.copyWith(color: kRedColor, fontSize: 12),
              ),
            );
          },
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          validator: validator,
        ),
        if (viewCustomCounter)
          Positioned(
            right: 10,
            bottom: 0,
            child: Text(
              '${controller?.text.length ?? 0}/${maxLength ?? 200}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
      ],
    );
  }
}
