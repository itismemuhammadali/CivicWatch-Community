import 'package:cctv_app/core/storage/app_settings_storage.dart';
import 'package:flutter/services.dart';

class AppFeedbackController {
  AppFeedbackController._();

  static final AppFeedbackController instance = AppFeedbackController._();
  static const AppSettingsStorage _settingsStorage = AppSettingsStorage();

  Future<void> playAlertFeedback() async {
    final notificationsEnabled = await _settingsStorage.readBool(
      AppSettingsKeys.generalNotification,
      fallback: true,
    );
    if (!notificationsEnabled) return;

    final soundEnabled = await _settingsStorage.readBool(
      AppSettingsKeys.sound,
      fallback: true,
    );
    final vibrateEnabled = await _settingsStorage.readBool(
      AppSettingsKeys.vibrate,
      fallback: true,
    );

    if (soundEnabled) {
      await SystemSound.play(SystemSoundType.alert);
    }

    if (vibrateEnabled) {
      await HapticFeedback.mediumImpact();
    }
  }

  Future<void> playTogglePreview({
    required bool soundEnabled,
    required bool vibrateEnabled,
  }) async {
    if (soundEnabled) {
      await SystemSound.play(SystemSoundType.click);
    }

    if (vibrateEnabled) {
      await HapticFeedback.selectionClick();
    }
  }
}
