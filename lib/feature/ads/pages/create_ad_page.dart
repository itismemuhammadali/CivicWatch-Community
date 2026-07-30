import 'package:cctv_app/core/components/app_alert.dart';
import 'package:cctv_app/core/components/custom_textfield.dart';
import 'package:cctv_app/core/components/primary_button.dart';
import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/network/api_exception.dart';
import 'package:cctv_app/core/network/models/ads_category.dart';
import 'package:cctv_app/core/network/services/application_cloud_service.dart';
import 'package:cctv_app/core/network/services/ads_service.dart';
import 'package:cctv_app/core/storage/auth_storage.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CreateAdPage extends StatefulWidget {
  const CreateAdPage({super.key});

  @override
  State<CreateAdPage> createState() => _CreateAdPageState();
}

class _CreateAdPageState extends State<CreateAdPage> {
  final AdsService _adsService = AdsService();
  final ApplicationCloudService _applicationCloudService =
      const ApplicationCloudService();
  final TextEditingController _headingController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _coverPhotoController = TextEditingController();

  static final List<AdsCategory> _defaultCategories = [
    AdsCategory(id: 1, name: 'Summer Sale', slug: 'summer-sale', isActive: true),
    AdsCategory(id: 2, name: 'Electronics', slug: 'electronics', isActive: true),
    AdsCategory(id: 3, name: 'Fashion & Wear', slug: 'fashion', isActive: true),
    AdsCategory(id: 4, name: 'Announcements', slug: 'announcements', isActive: true),
  ];

  List<AdsCategory> _categories = _defaultCategories;
  AdsCategory? _selectedCategory;
  bool _isLoadingCategories = false;
  String? _categoryError;
  bool _isUploadingCoverPhoto = false;
  String? _coverPhotoError;
  int? _coverPhotoMetaId;
  String? _coverPhotoUrl;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _headingController.dispose();
    _noteController.dispose();
    _coverPhotoController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _categoryError = null;
    });

    try {
      final accessToken = await const AuthStorage().readAccessToken();
      if (accessToken != null && accessToken.trim().isNotEmpty) {
        final apiCategories = await _adsService.getAdsCategory(accessToken: accessToken);
        final activeApi = apiCategories.where((c) => c.isActive).toList();
        if (activeApi.isNotEmpty) {
          if (!mounted) return;
          setState(() {
            _categories = [..._defaultCategories, ...activeApi];
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

  AdsCategory? _findCategoryBySlug(String? slug) {
    if (slug == null) return null;
    for (final category in _categories) {
      if (category.slug == slug) {
        return category;
      }
    }
    return null;
  }

  Future<void> _pickCoverPhoto() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery);
      if (file == null || !mounted) return;

      final accessToken = await const AuthStorage().readAccessToken() ?? 'demo_token';

      setState(() {
        _isUploadingCoverPhoto = true;
        _coverPhotoError = null;
        _coverPhotoController.text = 'Uploading image...';
      });

      final uploadedMedia = await _applicationCloudService.uploadImage(
        accessToken: accessToken,
        filePath: file.path,
        fileName: file.name,
        fileBytes: await file.readAsBytes(),
      );

      if (!mounted) return;
      setState(() {
        _coverPhotoMetaId = uploadedMedia.metaId;
        _coverPhotoUrl = uploadedMedia.metaUrl;
        _coverPhotoController.text = file.name;
      });

      AppAlert.showSuccess(context, 'Cover photo uploaded successfully');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _coverPhotoError = e.message;
        _coverPhotoController.clear();
      });
      AppAlert.showError(context, e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _coverPhotoError = 'Failed to upload cover photo';
        _coverPhotoController.clear();
      });
      AppAlert.showError(context, 'Failed to upload cover photo: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isUploadingCoverPhoto = false;
      });
    }
  }

  void _clearForm() {
    setState(() {
      _selectedCategory = null;
      _coverPhotoMetaId = null;
      _coverPhotoUrl = null;
      _coverPhotoError = null;
    });
    _headingController.clear();
    _noteController.clear();
    _coverPhotoController.clear();
  }

  Future<void> _submitAd() async {
    final title = _headingController.text.trim();
    final note = _noteController.text.trim();

    if (_selectedCategory == null) {
      AppAlert.showWarning(context, 'Please select a category');
      return;
    }
    if (title.isEmpty) {
      AppAlert.showWarning(context, 'Please enter ad heading');
      return;
    }
    if (note.isEmpty) {
      AppAlert.showWarning(context, 'Please enter important note');
      return;
    }
    if (_coverPhotoMetaId == null && (_coverPhotoUrl == null || _coverPhotoUrl!.isEmpty)) {
      AppAlert.showWarning(context, 'Please upload a cover photo first');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final now = DateTime.now();
      final timestamp = now.millisecondsSinceEpoch;

      await FirebaseFirestore.instance.collection('ads').doc('$timestamp').set({
        'id': timestamp,
        'title': title,
        'note': note,
        'categoryId': _selectedCategory!.id,
        'categoryName': _selectedCategory!.name,
        'coverImageUrl': _coverPhotoUrl ?? '',
        'coverMetaId': _coverPhotoMetaId ?? 0,
        'status': 'active',
        'createdAt': now.toIso8601String(),
        'startAt': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        'runDays': 30,
        'isGlobal': true,
      });

      // Try calling API service as well if available
      try {
        final accessToken = await const AuthStorage().readAccessToken();
        if (accessToken != null && accessToken.trim().isNotEmpty) {
          await _adsService.createAd(
            accessToken: accessToken,
            businessId: 0,
            categoryId: _selectedCategory!.id,
            title: title,
            note: note,
            destinationUrl: '',
            coverMetaId: _coverPhotoMetaId ?? 0,
            status: 'active',
          );
        }
      } catch (_) {}

      if (!mounted) return;
      AppAlert.showSuccess(context, 'Ad created & published successfully!');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      AppAlert.showError(context, 'Failed to create ad: $e');
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
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kBlackColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Create new ads", style: TextStyle(color: kBlackColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 10, left: 16.0, right: 16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Select Category", style: context.semiBold),
              Space.vertical(6),
              DropdownButtonFormField<String>(
                value: _selectedCategory?.slug,
                dropdownColor: kWhiteColor,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: kGreyColor),
                  ),
                ),
                hint: const Text("Select"),
                items: _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category.slug,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = _findCategoryBySlug(value);
                  });
                },
              ),
              if (_categoryError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _categoryError!,
                    style: context.normal.copyWith(color: kRedColor),
                  ),
                ),
              Space.vertical(20),
              Text("Heading", style: context.semiBold),
              Space.vertical(10),
              CustomTextField(
                controller: _headingController,
                maxLine: 3,
                hintText: "Write heading",
              ),
              Space.vertical(20),
              Text("Important note", style: context.semiBold),
              Space.vertical(10),
              CustomTextField(
                controller: _noteController,
                maxLine: 5,
                hintText: "Write message",
              ),
              Space.vertical(20),
              Text("Upload cover photo", style: context.semiBold),
              Space.vertical(10),
              CustomTextField(
                controller: _coverPhotoController,
                hintText: _isUploadingCoverPhoto ? "Uploading..." : "Upload",
                readOnly: true,
                enabled: !_isUploadingCoverPhoto,
                onTap: _isUploadingCoverPhoto ? null : _pickCoverPhoto,
                suffix: _isUploadingCoverPhoto
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.attach_file),
              ),
              if (_coverPhotoError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _coverPhotoError!,
                    style: context.normal.copyWith(color: kRedColor),
                  ),
                ),
              Space.vertical(24),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      text: "Clear",
                      textColor: kBlackColor,
                      borderColor: kPrimaryColor,
                      buttonColor: kWhiteColor,
                      showBorder: true,
                      onPressed: _isSubmitting ? () {} : _clearForm,
                      inactive: _isSubmitting || _isUploadingCoverPhoto,
                    ),
                  ),
                  Space.horizontal(10),
                  Expanded(
                    child: PrimaryButton(
                      text: "Boots now",
                      onPressed: _submitAd,
                      processing: _isSubmitting,
                      inactive: _isUploadingCoverPhoto,
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
