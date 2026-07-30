import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/services/app_feedback_controller.dart';
import 'package:cctv_app/core/storage/app_settings_storage.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AppSettingsStorage _settingsStorage = const AppSettingsStorage();
  final Map<String, bool> _settings = {
    AppSettingsKeys.generalNotification: true,
    AppSettingsKeys.sound: true,
    AppSettingsKeys.vibrate: true,
    AppSettingsKeys.appUpdates: false,
    AppSettingsKeys.billReminder: false,
    AppSettingsKeys.promotion: false,
    AppSettingsKeys.discountAvailable: false,
    AppSettingsKeys.paymentRequest: false,
    AppSettingsKeys.newServiceAvailable: false,
    AppSettingsKeys.newTipsAvailable: false,
  };

  bool _isLoading = true;

  static const List<_SettingsSection> _sections = [
    _SettingsSection(
      title: 'Common',
      items: [
        _SettingsItem(
          keyName: AppSettingsKeys.generalNotification,
          label: 'General Notification',
        ),
        _SettingsItem(keyName: AppSettingsKeys.sound, label: 'Sound'),
        _SettingsItem(keyName: AppSettingsKeys.vibrate, label: 'Vibrate'),
      ],
    ),
    _SettingsSection(
      title: 'System & Services Update',
      items: [
        _SettingsItem(
          keyName: AppSettingsKeys.appUpdates,
          label: 'App Updates',
        ),
        _SettingsItem(
          keyName: AppSettingsKeys.billReminder,
          label: 'Bill Reminder',
        ),
        _SettingsItem(
          keyName: AppSettingsKeys.promotion,
          label: 'Promotion',
        ),
        _SettingsItem(
          keyName: AppSettingsKeys.discountAvailable,
          label: 'Discount Available',
        ),
        _SettingsItem(
          keyName: AppSettingsKeys.paymentRequest,
          label: 'Payment Request',
        ),
      ],
    ),
    _SettingsSection(
      title: 'Others',
      items: [
        _SettingsItem(
          keyName: AppSettingsKeys.newServiceAvailable,
          label: 'New Service Available',
        ),
        _SettingsItem(
          keyName: AppSettingsKeys.newTipsAvailable,
          label: 'New Tips Available',
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final saved = await _settingsStorage.readAll();
    if (!mounted) return;
    setState(() {
      _settings.addAll(saved);
      _isLoading = false;
    });
  }

  Future<void> _updateSetting(String keyName, bool value) async {
    setState(() {
      _settings[keyName] = value;
    });

    await _settingsStorage.writeBool(keyName, value);

    final notificationsEnabled =
        _settings[AppSettingsKeys.generalNotification] ?? true;
    final soundEnabled = notificationsEnabled &&
        (_settings[AppSettingsKeys.sound] ?? false);
    final vibrateEnabled = notificationsEnabled &&
        (_settings[AppSettingsKeys.vibrate] ?? false);

    if (keyName == AppSettingsKeys.generalNotification ||
        keyName == AppSettingsKeys.sound ||
        keyName == AppSettingsKeys.vibrate) {
      await AppFeedbackController.instance.playTogglePreview(
        soundEnabled: soundEnabled,
        vibrateEnabled: vibrateEnabled,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhiteColor,
      appBar: AppBar(
        backgroundColor: kWhiteColor,
        surfaceTintColor: kWhiteColor,
        centerTitle: true,
        title: Text(
          'Settings',
          style: context.bold.copyWith(fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              itemCount: _sections.length,
              itemBuilder: (context, index) {
                final section = _sections[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (index > 0) Space.vertical(8),
                    Text(
                      section.title,
                      style: context.bold.copyWith(fontSize: 18),
                    ),
                    Space.vertical(4),
                    ...section.items.map((item) {
                      return Column(
                        children: [
                          _SettingsTile(
                            title: item.label,
                            value: _settings[item.keyName] ?? false,
                            onChanged: (value) =>
                                _updateSetting(item.keyName, value),
                          ),
                          const Divider(
                            height: 1,
                            color: Color(0xFFEEEEEE),
                          ),
                        ],
                      );
                    }),
                  ],
                );
              },
            ),
    );
  }
}

class _SettingsSectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSectionCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kGreyColor.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Text(
              title,
              style: context.semiBold.copyWith(fontSize: 18),
            ),
          ),
          ..._withDividers(children),
        ],
      ),
    );
  }

  List<Widget> _withDividers(List<Widget> children) {
    final widgets = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      widgets.add(children[i]);
      if (i != children.length - 1) {
        widgets.add(
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: kGreyColor.withValues(alpha: 0.45),
          ),
        );
      }
    }
    return widgets;
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: context.normal.copyWith(
                  fontSize: 15,
                  color: kBlackColor,
                ),
              ),
            ),
            Switch.adaptive(
              value: value,
              activeColor: kWhiteColor,
              activeTrackColor: kPrimaryColor,
              inactiveThumbColor: kWhiteColor,
              inactiveTrackColor: kContainerGreyColor,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection {
  final String title;
  final List<_SettingsItem> items;

  const _SettingsSection({
    required this.title,
    required this.items,
  });
}

class _SettingsItem {
  final String keyName;
  final String label;

  const _SettingsItem({
    required this.keyName,
    required this.label,
  });
}
