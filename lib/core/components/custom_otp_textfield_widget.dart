import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class CustomOtpTextfieldWidget extends StatefulWidget {
  /// A custom OTP text field widget that supports single digit input and paste functionality.
  ///
  /// When a user pastes text into this field:
  /// - If the pasted text is longer than 1 character, it triggers the [onPaste] callback
  /// - The [onPaste] callback receives the full pasted text for processing
  /// - This allows the parent widget to distribute the pasted digits across multiple OTP fields
  const CustomOtpTextfieldWidget({
    super.key,
    this.onChanged,
    this.onSubmitted,
    this.fieldColor,
    this.controller,
    this.focusNode,
    this.onTapOutside,
    this.onPaste,
  });

  /// Called when the text changes (for single character input)
  final Function(String)? onChanged;

  /// Called when the text is submitted
  final Function(String)? onSubmitted;

  /// The background color of the text field
  final Color? fieldColor;

  /// The text editing controller
  final TextEditingController? controller;

  /// The focus node for this field
  final FocusNode? focusNode;

  /// Called when tapping outside the field
  final ValueChanged<PointerDownEvent>? onTapOutside;

  /// Called when text is pasted (text length > 1 character)
  /// The callback receives the full pasted text for distribution across OTP fields
  final Function(String)? onPaste;

  @override
  State<CustomOtpTextfieldWidget> createState() =>
      _CustomOtpTextfieldWidgetState();
}

class _CustomOtpTextfieldWidgetState extends State<CustomOtpTextfieldWidget> {
  String? _lastText = '';

  @override
  Widget build(BuildContext context) {
    return TextField(
      autofillHints: const <String>[AutofillHints.oneTimeCode],
      controller: widget.controller,
      focusNode: widget.focusNode,
      onTapOutside:
          widget.onTapOutside ??
          (_) => FocusManager.instance.primaryFocus?.unfocus(),
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      onChanged: (value) {
        // Check if this is a paste operation by comparing with previous text
        if (_lastText != null &&
            value.length > _lastText!.length + 1 &&
            widget.onPaste != null) {
          // This is likely a paste operation - get the full pasted text
          final pastedText = value.substring(_lastText!.length);
          if (pastedText.length > 1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.onPaste!(pastedText);
              // Clear this field after triggering paste
              widget.controller?.clear();
            });
            return;
          }
        }

        // Normal single character input - limit to 1 character
        if (value.length > 1) {
          widget.controller?.text = value[0];
          widget.controller?.selection = TextSelection.collapsed(offset: 1);
        }

        // Normal single character input
        if (widget.onChanged != null) {
          widget.onChanged!(value.length > 1 ? value[0] : value);
        }

        _lastText = value;
      },
      onTap: () {
        // Select all text when tapped for easy replacement
        if (widget.controller?.text.isNotEmpty == true) {
          widget.controller?.selection = TextSelection(
            baseOffset: 0,
            extentOffset: widget.controller!.text.length,
          );
        }
      },
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        // Custom formatter to handle paste operations
        _OtpPasteFormatter(onPaste: widget.onPaste),
      ],
      decoration: InputDecoration(
        hintText: '-',
        counterText: '',
        filled: true,
        fillColor: widget.fieldColor ?? kLightGreyColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: widget.fieldColor ?? kLightGreyColor,
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: widget.fieldColor ?? kLightGreyColor,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: kLightBlueColor, width: 2.0),
        ),
      ),
    );
  }
}

class _OtpPasteFormatter extends TextInputFormatter {
  final Function(String)? onPaste;

  _OtpPasteFormatter({this.onPaste});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // If the new value is longer than 1 character, it's likely a paste
    if (newValue.text.length > 1 && onPaste != null) {
      // Call the paste callback with the full pasted text
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onPaste!(newValue.text);
      });
      // Return only the first character for this field
      return TextEditingValue(
        text: newValue.text.isNotEmpty ? newValue.text[0] : '',
        selection: TextSelection.collapsed(offset: 1),
      );
    }
    return newValue;
  }
}