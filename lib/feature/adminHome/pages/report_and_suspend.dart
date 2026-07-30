import 'package:cctv_app/core/components/app_alert.dart';
import 'package:cctv_app/core/components/custom_switch_button.dart';
import 'package:cctv_app/core/components/custom_textfield.dart';
import 'package:cctv_app/core/components/primary_button.dart';
import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/network/api_exception.dart';
import 'package:cctv_app/core/network/services/admin_control_service.dart';
import 'package:cctv_app/core/storage/auth_storage.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/core/utils/validators.dart';
import 'package:flutter/material.dart';

enum ReportAction { suspend, warning }

class ReportAndSuspend extends StatefulWidget {
  final ReportAction initialAction;
  final int? targetUserId;
  final int attachedMetaId;

  const ReportAndSuspend({
    super.key,
    this.initialAction = ReportAction.suspend,
    this.targetUserId,
    this.attachedMetaId = 0,
  });

  @override
  State<ReportAndSuspend> createState() => _ReportAndSuspendState();
}

class _ReportAndSuspendState extends State<ReportAndSuspend> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _noteController = TextEditingController();

  late bool sendWarning;
  late bool suspendAccount;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    sendWarning = widget.initialAction == ReportAction.warning;
    suspendAccount = widget.initialAction == ReportAction.suspend;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _toggleSuspend(bool value) {
    if (!value) return;

    setState(() {
      suspendAccount = true;
      sendWarning = false;
    });
  }

  void _toggleWarning(bool value) {
    if (!value) return;

    setState(() {
      sendWarning = true;
      suspendAccount = false;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (!sendWarning && !suspendAccount) {
      AppAlert.showWarning(context, 'Please select an action');
      return;
    }

    final targetUserId = widget.targetUserId;
    if (targetUserId == null || targetUserId <= 0) {
      AppAlert.showError(context, 'User id not found');
      return;
    }

    if (suspendAccount) {
      final confirmed = await _confirmBlockUser();
      if (!confirmed) return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final accessToken = await const AuthStorage().readAccessToken();
      if (accessToken == null || accessToken.trim().isEmpty) {
        throw const ApiException('Session token not found');
      }

      final service = AdminControlService();
      if (suspendAccount) {
        await service.blockUser(
          accessToken: accessToken,
          userId: targetUserId,
          reason: _noteController.text.trim(),
        );
      } else {
        await service.sendWarningToUser(
          accessToken: accessToken,
          userId: targetUserId,
          alertNote: _noteController.text.trim(),
          attachedMetaId: widget.attachedMetaId,
        );
      }

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      AppAlert.showSuccess(
        context,
        suspendAccount
            ? 'User blocked successfully'
            : 'Warning sent successfully',
      );
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      AppAlert.showError(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      AppAlert.showError(
        context,
        suspendAccount ? 'Failed to block user' : 'Failed to send warning',
      );
    }
  }

  Future<bool> _confirmBlockUser() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: kWhiteColor,
              title: const Text('Block User'),
              content: const Text('You want to block this user?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Block'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhiteColor,
      appBar: AppBar(
        backgroundColor: kWhiteColor,
        centerTitle: true,
        title: const Text('Block/Suspend'),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 10, left: 16.0, right: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Note',
                        style: context.normal.copyWith(fontSize: 16),
                      ),
                      Space.vertical(8),
                      CustomTextField(
                        controller: _noteController,
                        hintText: 'Write Note',
                        maxLine: 6,
                        validator: Validators.required,
                      ),
                      Space.vertical(16),
                      Text(
                        'Take Action',
                        style: context.semiBold.copyWith(fontSize: 16),
                      ),
                      Space.vertical(8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Block/Suspends account',
                            style: context.normal.copyWith(fontSize: 16),
                          ),
                          CustomSwitchButton(
                            onToggle: _toggleSuspend,
                            isToggled: suspendAccount,
                          ),
                        ],
                      ),
                      Space.vertical(16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Send Warning',
                            style: context.normal.copyWith(fontSize: 16),
                          ),
                          CustomSwitchButton(
                            onToggle: _toggleWarning,
                            isToggled: sendWarning,
                          ),
                        ],
                      ),
                      Space.vertical(16),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      text: 'Cancel',
                      borderColor: kPrimaryColor,
                      buttonColor: kWhiteColor,
                      textColor: kBlackColor,
                      showBorder: true,
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ),
                  Space.horizontal(10),
                  Expanded(
                    child: PrimaryButton(
                      text: 'Submit',
                      processing: _isSubmitting,
                      inactive: _isSubmitting,
                      onPressed: _submit,
                    ),
                  ),
                ],
              ),
              Space.vertical(30),
            ],
          ),
        ),
      ),
    );
  }
}
