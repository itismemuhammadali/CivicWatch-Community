import 'dart:async';

import 'package:cctv_app/core/services/app_feedback_controller.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:flutter/material.dart';

enum AppAlertType { success, error, warning, info }

class AppAlert {
  const AppAlert._();

  static void showSuccess(BuildContext context, String message) {
    _show(context, message, AppAlertType.success);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, AppAlertType.error);
  }

  static void showWarning(BuildContext context, String message) {
    _show(context, message, AppAlertType.warning);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message, AppAlertType.info);
  }

  static void _show(
    BuildContext context,
    String message,
    AppAlertType type,
  ) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    unawaited(AppFeedbackController.instance.playAlertFeedback());

    final theme = Theme.of(context);
    final style = _styleFor(type);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          padding: EdgeInsets.zero,
          content: Container(
            decoration: BoxDecoration(
              color: style.backgroundColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: kBlackColor.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: style.borderColor,
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: style.iconBackgroundColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(style.icon, color: style.foregroundColor, size: 28),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 18),
                    child: Text(
                      message,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: style.foregroundColor,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  static _AppAlertStyle _styleFor(AppAlertType type) {
    switch (type) {
      case AppAlertType.success:
        return const _AppAlertStyle(
          foregroundColor: Color(0xFF1D7A43),
          backgroundColor: Color(0xFFF1FBF4),
          borderColor: Color(0xFFBFE7CA),
          iconBackgroundColor: Color(0xFFDFF5E5),
          icon: Icons.check_circle_outline_rounded,
        );
      case AppAlertType.error:
        return const _AppAlertStyle(
          foregroundColor: Color(0xFFC34A36),
          backgroundColor: Color(0xFFFFF4F1),
          borderColor: Color(0xFFF4C9C1),
          iconBackgroundColor: Color(0xFFFFE3DD),
          icon: Icons.error_outline_rounded,
        );
      case AppAlertType.warning:
        return const _AppAlertStyle(
          foregroundColor: Color(0xFFD38518),
          backgroundColor: Color(0xFFFFF7EA),
          borderColor: Color(0xFFF2D3A1),
          iconBackgroundColor: Color(0xFFFFE6BE),
          icon: Icons.warning_amber_rounded,
        );
      case AppAlertType.info:
        return const _AppAlertStyle(
          foregroundColor: kPrimaryColor,
          backgroundColor: Color(0xFFF2F7FF),
          borderColor: Color(0xFFBEDBFF),
          iconBackgroundColor: Color(0xFFDDEEFF),
          icon: Icons.info_outline_rounded,
        );
    }
  }
}

class _AppAlertStyle {
  final Color foregroundColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconBackgroundColor;
  final IconData icon;

  const _AppAlertStyle({
    required this.foregroundColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconBackgroundColor,
    required this.icon,
  });
}
