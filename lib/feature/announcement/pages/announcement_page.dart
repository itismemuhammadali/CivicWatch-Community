import 'dart:typed_data';

import 'package:cctv_app/core/components/app_alert.dart';
import 'package:cctv_app/core/components/admin_top_header.dart';
import 'package:cctv_app/core/components/custom_dropdown.dart';
import 'package:cctv_app/core/components/custom_textfield.dart';
import 'package:cctv_app/core/components/primary_button.dart';
import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/network/api_exception.dart';
import 'package:cctv_app/core/network/models/general_parameter_option.dart';
import 'package:cctv_app/core/network/services/admin_control_service.dart';
import 'package:cctv_app/core/network/services/application_cloud_service.dart';
import 'package:cctv_app/core/network/services/general_parameter_service.dart';
import 'package:cctv_app/core/storage/auth_storage.dart';
import 'package:cctv_app/core/theme/app_colors.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/feature/home/pages/history_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AnnouncementPage extends StatefulWidget {
  const AnnouncementPage({super.key});

  @override
  State<AnnouncementPage> createState() => _AnnouncementPageState();
}

class _AnnouncementPageState extends State<AnnouncementPage> {
  static const _alertCategoryHeader = 'ALERT_CATEGORY_TYPE';
  final GeneralParameterService _generalParameterService =
      const GeneralParameterService();
  final AdminControlService _adminControlService = AdminControlService();
  final ApplicationCloudService _applicationCloudService =
      const ApplicationCloudService();
  final TextEditingController _attachmentController = TextEditingController();
  final TextEditingController _alertNoteController = TextEditingController();

  static final List<GeneralParameterOption> _defaultCategories = [
    const GeneralParameterOption(paramDetailId: 1, paramHeader: 'ALERT_CATEGORY_TYPE', paramValue: 'General Alert', paramLabel: 'General Alert'),
    const GeneralParameterOption(paramDetailId: 2, paramHeader: 'ALERT_CATEGORY_TYPE', paramValue: 'Emergency', paramLabel: 'Emergency'),
    const GeneralParameterOption(paramDetailId: 3, paramHeader: 'ALERT_CATEGORY_TYPE', paramValue: 'Warning', paramLabel: 'Warning'),
    const GeneralParameterOption(paramDetailId: 4, paramHeader: 'ALERT_CATEGORY_TYPE', paramValue: 'System Update', paramLabel: 'System Update'),
  ];

  List<GeneralParameterOption> _categories = _defaultCategories;
  String? _selectedCategory;
  bool _isLoadingCategories = false;
  bool _isUploadingAttachment = false;
  bool _isSubmittingAlert = false;
  String? _categoryLoadError;
  String? _attachmentError;
  int? _attachmentMetaId;
  String? _uploadedMediaUrl;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _attachmentController.dispose();
    _alertNoteController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _categoryLoadError = null;
    });

    try {
      final accessToken = await const AuthStorage().readAccessToken();
      if (accessToken != null && accessToken.trim().isNotEmpty) {
        final categories = await _generalParameterService.getByHeaderName(
          headerName: _alertCategoryHeader,
          accessToken: accessToken,
        );

        if (categories.isNotEmpty) {
          if (!mounted) return;
          setState(() {
            _categories = [..._defaultCategories, ...categories];
          });
          return;
        }
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _categories = _defaultCategories;
      _isLoadingCategories = false;
    });
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery);
      if (file == null || !mounted) return;
      final fileBytes = await file.readAsBytes();

      await _uploadSelectedImage(
        filePath: file.path,
        fileName: file.name,
        fileBytes: fileBytes,
      );
    } catch (e) {
      if (!mounted) return;
      AppAlert.showError(context, 'Failed to pick image from gallery: $e');
    }
  }

  Future<void> _uploadSelectedImage({
    required String filePath,
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    setState(() {
      _isUploadingAttachment = true;
      _attachmentError = null;
    });

    try {
      final accessToken = await const AuthStorage().readAccessToken() ?? 'demo_token';

      final uploadedMedia = await _applicationCloudService.uploadImage(
        accessToken: accessToken,
        filePath: filePath,
        fileBytes: fileBytes,
        fileName: fileName,
      );

      if (!mounted) return;
      setState(() {
        _attachmentMetaId = uploadedMedia.metaId;
        _uploadedMediaUrl = uploadedMedia.metaUrl;
        _attachmentController.text = fileName;
      });

      AppAlert.showSuccess(context, 'Attachment uploaded successfully');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _attachmentError = e.message;
      });
      AppAlert.showError(context, e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _attachmentError = 'Failed to upload image';
      });
      AppAlert.showError(context, 'Failed to upload image: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isUploadingAttachment = false;
      });
    }
  }

  void _clearForm() {
    setState(() {
      _selectedCategory = null;
      _attachmentMetaId = null;
      _uploadedMediaUrl = null;
      _attachmentError = null;
    });
    _attachmentController.clear();
    _alertNoteController.clear();
  }

  Future<void> _submitAlert() async {
    final category = _selectedCategory?.trim();
    final alertNote = _alertNoteController.text.trim();

    if (category == null || category.isEmpty) {
      AppAlert.showWarning(context, 'Please select a category.');
      return;
    }
    if (alertNote.isEmpty) {
      AppAlert.showWarning(context, 'Please enter alert note.');
      return;
    }

    setState(() {
      _isSubmittingAlert = true;
    });

    try {
      final storage = const AuthStorage();
      final accessToken = await storage.readAccessToken() ?? 'demo_token';
      final userId = await storage.readUserId() ?? 1;

      await _adminControlService.createApplicationAlert(
        accessToken: accessToken,
        createdBy: userId,
        category: category,
        alertNote: alertNote,
        attachedMetaId: _attachmentMetaId ?? 0,
        mediaUrl: _uploadedMediaUrl,
      );

      if (!mounted) return;
      _clearForm();
      AppAlert.showSuccess(context, 'Announcement sent to all users and admins!');
    } catch (e) {
      if (!mounted) return;
      AppAlert.showError(context, 'Failed to submit alert: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmittingAlert = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 350;
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 16.0, right: 16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminTopHeader(),
            Space.vertical(20),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HistoryScreen(),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kGreyColor),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.history),
                      Space.horizontal(4),
                      Text("History", style: context.normal),
                    ],
                  ),
                ),
              ),
            ),
            Space.vertical(10),
            Center(
              child: Text(
                "Send Alerts",
                style: context.bold.copyWith(fontSize: 24),
              ),
            ),
            Space.vertical(10),
            Text("Select Category", style: context.bold),
            Space.vertical(10),
            CustomDropdown(
              value: _selectedCategory,
              items: _categories
                  .map(
                    (category) => DropdownMenuItem<String>(
                      value: category.paramValue,
                      child: Text(
                        category.paramLabel,
                        style: TextStyle(color: AppColors.blackColor),
                      ),
                    ),
                  )
                  .toList(),
              hint: "Select Category",
              screenWidth: screenWidth,
              isSmallScreen: isSmallScreen,
              isSearchable: true,
              openSearchInPopup: false,
              searchHintText: "Search category",
              enabled: true,
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
            ),
            Space.vertical(20),
            Text("Important Note", style: context.bold),
            Space.vertical(10),
            CustomTextField(
              controller: _alertNoteController,
              hintText: "Write message",
              hintTextColor: kDarkGreyColor,
              maxLine: 6,
            ),
            Space.vertical(20),
            Text(
              "Attached file (Optional)",
              style: context.bold.copyWith(fontSize: 13),
            ),
            Space.vertical(10),
            CustomTextField(
              controller: _attachmentController,
              hintText: "Attached file",
              hintTextColor: kDarkGreyColor,
              readOnly: true,
              enabled: !_isUploadingAttachment,
              onTap: _isUploadingAttachment ? null : _pickImageFromGallery,
              suffix: _isUploadingAttachment
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(
                        Icons.attach_file,
                        size: 20,
                        color: kDarkGreyColor,
                      ),
                    ),
            ),
            if (_attachmentError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _attachmentError!,
                    style: const TextStyle(color: kRedColor, fontSize: 12),
                  ),
                ),
              ),
            Space.vertical(20),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    text: "Clear",
                    buttonColor: kWhiteColor,
                    textColor: kBlackColor,
                    borderColor: kGreyColor,
                    showBorder: true,
                    onPressed: _clearForm,
                  ),
                ),
                Space.horizontal(10),
                Expanded(
                  child: PrimaryButton(
                    text: "Send",
                    onPressed: _submitAlert,
                    processing: _isSubmittingAlert,
                    inactive: _isUploadingAttachment,
                  ),
                ),
              ],
            ),
            Space.vertical(24),
          ],
        ),
      ),
    );
  }
}
