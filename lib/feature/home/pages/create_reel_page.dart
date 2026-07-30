import 'dart:typed_data';

import 'package:cctv_app/core/components/custom_textfield.dart';
import 'package:cctv_app/core/components/app_alert.dart';
import 'package:cctv_app/core/components/primary_button.dart';
import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/network/api_exception.dart';
import 'package:cctv_app/core/network/models/uploaded_media.dart';
import 'package:cctv_app/core/network/services/application_cloud_service.dart';
import 'package:cctv_app/core/network/services/user_case_service.dart';
import 'package:cctv_app/core/storage/auth_storage.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/core/utils/validators.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CreateReelPage extends StatefulWidget {
  const CreateReelPage({super.key});

  @override
  State<CreateReelPage> createState() => _CreateReelPageState();
}

class _CreateReelPageState extends State<CreateReelPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isUploading = false;
  bool _isSubmitting = false;
  String? _selectedFilePath;
  String? _selectedFileName;
  int? _uploadedMetaId;
  bool? _isVideoMedia;
  Uint8List? _selectedImageBytes;

  bool get _hasUploadedMedia => _uploadedMetaId != null;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    if (_isUploading || _isSubmitting) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: kWhiteColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select reel media',
                  style: context.bold.copyWith(fontSize: 18),
                ),
                Space.vertical(12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.image_outlined),
                  title: const Text('Image from gallery'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImage();
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.videocam_outlined),
                  title: const Text('Video from gallery'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickVideo();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage() async {
    if (_isUploading || _isSubmitting) return;

    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery);
      if (file == null || !mounted) return;

      await _uploadMedia(file, isVideo: false);
    } catch (e) {
      if (!mounted) return;
      AppAlert.showError(context, 'Failed to pick image: $e');
    }
  }

  Future<void> _pickVideo() async {
    if (_isUploading || _isSubmitting) return;

    try {
      final picker = ImagePicker();
      final file = await picker.pickVideo(source: ImageSource.gallery);
      if (file == null || !mounted) return;

      await _uploadMedia(file, isVideo: true);
    } catch (e) {
      if (!mounted) return;
      AppAlert.showError(context, 'Failed to pick video: $e');
    }
  }

  Future<void> _uploadMedia(XFile file, {required bool isVideo}) async {
    setState(() {
      _isUploading = true;
      _selectedFilePath = file.path;
      _selectedFileName = file.name;
      _uploadedMetaId = null;
      _isVideoMedia = isVideo;
      _selectedImageBytes = null;
    });

    try {
      final accessToken = await const AuthStorage().readAccessToken();
      if (accessToken == null || accessToken.trim().isEmpty) {
        throw const ApiException('Session token not found');
      }

      final fileBytes = await file.readAsBytes();

      const service = ApplicationCloudService();
      final UploadedMedia uploadedMedia = isVideo
          ? await service.uploadVideo(
              accessToken: accessToken,
              filePath: file.path,
              fileBytes: fileBytes,
              fileName: file.name,
            )
          : await service.uploadImage(
              accessToken: accessToken,
              filePath: file.path,
              fileBytes: fileBytes,
              fileName: file.name,
            );

      if (!mounted) return;
      setState(() {
        _uploadedMetaId = uploadedMedia.metaId;
        _selectedImageBytes = isVideo ? null : fileBytes;
      });
      AppAlert.showSuccess(
        context,
        isVideo ? 'Video uploaded successfully' : 'Image uploaded successfully',
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _selectedFilePath = null;
        _selectedFileName = null;
        _isVideoMedia = null;
        _selectedImageBytes = null;
      });
      AppAlert.showError(context, e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _selectedFilePath = null;
        _selectedFileName = null;
        _isVideoMedia = null;
        _selectedImageBytes = null;
      });
      AppAlert.showError(
        context,
        isVideo ? 'Failed to upload video: $e' : 'Failed to upload image: $e',
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _submitReel() async {
    if (_isSubmitting || _isUploading) return;
    if (_formKey.currentState?.validate() != true) return;
    if (_uploadedMetaId == null) {
      AppAlert.showWarning(context, 'Please upload an image or video first');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final accessToken = await const AuthStorage().readAccessToken();
      if (accessToken == null || accessToken.trim().isEmpty) {
        throw const ApiException('Session token not found');
      }

      await UserCaseService().createUserReel(
        accessToken: accessToken,
        reelMetaId: _uploadedMetaId!,
        reelDescription: _descriptionController.text.trim(),
      );

      if (!mounted) return;
      AppAlert.showSuccess(context, 'Reel created successfully');
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      AppAlert.showError(context, e.message);
    } catch (e) {
      if (!mounted) return;
      AppAlert.showError(context, 'Failed to create reel: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhiteColor,
      appBar: AppBar(
        backgroundColor: kWhiteColor,
        surfaceTintColor: kWhiteColor,
        title: const Text('Create Reel'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upload an image or video and publish it as a reel with a short description.',
                  style: context.normal.copyWith(color: kDarkGreyColor),
                ),
                Space.vertical(16),
                _buildUploadCard(context),
                Space.vertical(16),
                CustomTextField(
                  controller: _descriptionController,
                  hintText: 'Write reel description',
                  maxLine: 4,
                  minLines: 4,
                  maxLength: 250,
                  viewCustomCounter: true,
                  textCapitalization: TextCapitalization.sentences,
                  validator: Validators.required,
                ),
                Space.vertical(20),
                PrimaryButton(
                  text: 'Create Reel',
                  processing: _isSubmitting,
                  inactive: _isUploading || _isSubmitting,
                  onPressed: _submitReel,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhiteColor,
        border: Border.all(color: kGreyColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reel media', style: context.semiBold.copyWith(fontSize: 16)),
          Space.vertical(12),
          if (_selectedFilePath != null) _buildMediaPreview(),
          if (_selectedFileName != null) ...[
            Space.vertical(12),
            Text(
              _selectedFileName!,
              style: context.normal.copyWith(color: kDarkGreyColor),
            ),
          ],
          if (_hasUploadedMedia) ...[
            Space.vertical(8),
            Text(
              'Uploaded meta_id: $_uploadedMetaId',
              style: context.normal.copyWith(color: kPrimaryColor),
            ),
          ],
          Space.vertical(16),
          PrimaryButton(
            text: _hasUploadedMedia ? 'Replace Media' : 'Browse Media',
            buttonColor: kWhiteColor,
            textColor: kBlackColor,
            showBorder: true,
            borderColor: kPrimaryColor,
            processing: _isUploading,
            inactive: _isUploading || _isSubmitting,
            onPressed: _pickMedia,
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview() {
    if (_selectedFilePath == null) {
      return const SizedBox.shrink();
    }

    if (_isVideoMedia == true) {
      return Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: kContainerGreyColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kGreyColor),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.video_library_outlined,
              size: 48,
              color: kDarkGreyColor,
            ),
            Space.vertical(8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                _selectedFileName ?? 'Video selected',
                textAlign: TextAlign.center,
                style: context.normal.copyWith(color: kDarkGreyColor),
              ),
            ),
            if (kIsWeb) ...[
              Space.vertical(6),
              Text(
                'Video preview is limited on web before upload.',
                textAlign: TextAlign.center,
                style: context.normal.copyWith(
                  color: kDarkGreyColor,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 220,
        width: double.infinity,
        color: kContainerGreyColor,
        child: _selectedImageBytes == null
            ? const Center(child: CircularProgressIndicator())
            : Image.memory(_selectedImageBytes!, fit: BoxFit.cover),
      ),
    );
  }
}
