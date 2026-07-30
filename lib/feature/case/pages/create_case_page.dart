import 'dart:typed_data';

import 'package:cctv_app/core/components/app_alert.dart';
import 'package:cctv_app/core/components/custom_dropdown.dart';
import 'package:cctv_app/core/components/custom_textfield.dart';
import 'package:cctv_app/core/components/plain_selection_widget.dart';
import 'package:cctv_app/core/components/primary_button.dart';
import 'package:cctv_app/core/components/search_bar_header.dart';
import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/network/api_exception.dart';
import 'package:cctv_app/core/network/models/general_parameter_option.dart';
import 'package:cctv_app/core/network/models/uploaded_media.dart';
import 'package:cctv_app/core/network/models/user_option.dart';
import 'package:cctv_app/core/network/services/application_cloud_service.dart';
import 'package:cctv_app/core/network/services/general_parameter_service.dart';
import 'package:cctv_app/core/network/services/user_case_service.dart';
import 'package:cctv_app/core/network/services/user_service.dart';
import 'package:cctv_app/core/storage/auth_storage.dart';
import 'package:cctv_app/core/theme/app_colors.dart';
import 'package:cctv_app/core/utils/assets.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/core/utils/validators.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';

class CreateCasePage extends StatefulWidget {
  final VoidCallback? onCaseCreated;

  const CreateCasePage({super.key, this.onCaseCreated});

  @override
  State<CreateCasePage> createState() => _CreateCasePageState();
}

class _CreateCasePageState extends State<CreateCasePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _caseTitleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool isMarkAsRead = false;
  bool _hasTriedSubmit = false;
  String? _selectedCategory;
  String? _selectedDefendant;
  String? _selectedViewCategory;
  String? _selectedAvailabilityType;
  bool _isLoadingCategories = true;
  bool _isLoadingDefendants = true;
  bool _isLoadingViewCategories = true;
  bool _isLoadingAvailabilityTypes = true;
  bool _isUploadingAttachment = false;
  bool _isSubmittingCase = false;
  String? _categoryLoadError;
  String? _defendantLoadError;
  String? _viewCategoryLoadError;
  String? _availabilityTypeLoadError;
  final List<Map<String, dynamic>> _uploadedMediaList = [];
  String? _attachmentError;
  List<GeneralParameterOption> _categories = const [];
  List<UserOption> _defendants = const [];
  List<GeneralParameterOption> _viewCategories = const [];
  List<GeneralParameterOption> _availabilityTypes = const [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadDefendants();
    _loadViewCategories();
    _loadAvailabilityTypes();
  }

  @override
  void dispose() {
    _caseTitleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _categoryLoadError = null;
    });
    try {
      final storage = const AuthStorage();
      final accessToken = await storage.readAccessToken() ?? '';
      var categories = await const GeneralParameterService().getByHeaderName(
        headerName: 'CASE_CATEGORY',
        accessToken: accessToken,
      );
      if (categories.isEmpty) {
        categories = const [
          GeneralParameterOption(paramDetailId: 1, paramHeader: 'CASE_CATEGORY', paramLabel: 'Family Affairs', paramValue: 'FA'),
          GeneralParameterOption(paramDetailId: 2, paramHeader: 'CASE_CATEGORY', paramLabel: 'Divorce', paramValue: 'DV'),
          GeneralParameterOption(paramDetailId: 3, paramHeader: 'CASE_CATEGORY', paramLabel: 'Neighborhood conflicts', paramValue: 'NC'),
          GeneralParameterOption(paramDetailId: 4, paramHeader: 'CASE_CATEGORY', paramLabel: 'Property disputes', paramValue: 'PD'),
          GeneralParameterOption(paramDetailId: 5, paramHeader: 'CASE_CATEGORY', paramLabel: 'Custody', paramValue: 'CU'),
        ];
      }
      if (!mounted) return;
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _categories = const [
          GeneralParameterOption(paramDetailId: 1, paramHeader: 'CASE_CATEGORY', paramLabel: 'Family Affairs', paramValue: 'FA'),
          GeneralParameterOption(paramDetailId: 2, paramHeader: 'CASE_CATEGORY', paramLabel: 'Divorce', paramValue: 'DV'),
          GeneralParameterOption(paramDetailId: 3, paramHeader: 'CASE_CATEGORY', paramLabel: 'Neighborhood conflicts', paramValue: 'NC'),
          GeneralParameterOption(paramDetailId: 4, paramHeader: 'CASE_CATEGORY', paramLabel: 'Property disputes', paramValue: 'PD'),
          GeneralParameterOption(paramDetailId: 5, paramHeader: 'CASE_CATEGORY', paramLabel: 'Custody', paramValue: 'CU'),
        ];
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _loadDefendants() async {
    setState(() {
      _isLoadingDefendants = true;
      _defendantLoadError = null;
    });

    try {
      final storage = const AuthStorage();
      final accessToken = await storage.readAccessToken() ?? '';
      final defendants = await const UserService().getAllUsers(
        accessToken: accessToken,
      );
      final currentUserId = await storage.readUserId();
      
      if (!mounted) return;
      setState(() {
        _defendants = defendants.where((d) => d.userId != currentUserId).toList();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _defendantLoadError = null;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingDefendants = false;
      });
    }
  }

  Future<void> _loadViewCategories() async {
    setState(() {
      _isLoadingViewCategories = true;
      _viewCategoryLoadError = null;
    });
    try {
      final storage = const AuthStorage();
      final accessToken = await storage.readAccessToken() ?? '';
      var viewCategories = await const GeneralParameterService().getByHeaderName(
        headerName: 'CASE_VIEW_CATEGORY',
        accessToken: accessToken,
      );
      if (viewCategories.isEmpty) {
        viewCategories = const [
          GeneralParameterOption(paramDetailId: 6, paramHeader: 'CASE_VIEW_CATEGORY', paramLabel: 'Public', paramValue: 'PUB'),
          GeneralParameterOption(paramDetailId: 7, paramHeader: 'CASE_VIEW_CATEGORY', paramLabel: 'Jury', paramValue: 'JRY'),
          GeneralParameterOption(paramDetailId: 8, paramHeader: 'CASE_VIEW_CATEGORY', paramLabel: 'Private', paramValue: 'PRV'),
        ];
      }
      if (!mounted) return;
      setState(() {
        _viewCategories = viewCategories;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _viewCategories = const [
          GeneralParameterOption(paramDetailId: 6, paramHeader: 'CASE_VIEW_CATEGORY', paramLabel: 'Public', paramValue: 'PUB'),
          GeneralParameterOption(paramDetailId: 7, paramHeader: 'CASE_VIEW_CATEGORY', paramLabel: 'Jury', paramValue: 'JRY'),
          GeneralParameterOption(paramDetailId: 8, paramHeader: 'CASE_VIEW_CATEGORY', paramLabel: 'Private', paramValue: 'PRV'),
        ];
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingViewCategories = false;
      });
    }
  }

  Future<void> _loadAvailabilityTypes() async {
    setState(() {
      _isLoadingAvailabilityTypes = true;
      _availabilityTypeLoadError = null;
    });
    try {
      final storage = const AuthStorage();
      final accessToken = await storage.readAccessToken() ?? '';
      var availabilityTypes = await const GeneralParameterService().getByHeaderName(
        headerName: 'CASE_AVAILIBILITY_TYPE',
        accessToken: accessToken,
      );
      if (availabilityTypes.isEmpty) {
        availabilityTypes = const [
          GeneralParameterOption(paramDetailId: 9, paramHeader: 'CASE_AVAILIBILITY_TYPE', paramLabel: '24 hours', paramValue: '24H'),
          GeneralParameterOption(paramDetailId: 10, paramHeader: 'CASE_AVAILIBILITY_TYPE', paramLabel: 'week', paramValue: 'WK'),
          GeneralParameterOption(paramDetailId: 11, paramHeader: 'CASE_AVAILIBILITY_TYPE', paramLabel: 'Month', paramValue: 'MN'),
        ];
      }
      if (!mounted) return;
      setState(() {
        _availabilityTypes = availabilityTypes;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _availabilityTypes = const [
          GeneralParameterOption(paramDetailId: 9, paramHeader: 'CASE_AVAILIBILITY_TYPE', paramLabel: '24 hours', paramValue: '24H'),
          GeneralParameterOption(paramDetailId: 10, paramHeader: 'CASE_AVAILIBILITY_TYPE', paramLabel: 'week', paramValue: 'WK'),
          GeneralParameterOption(paramDetailId: 11, paramHeader: 'CASE_AVAILIBILITY_TYPE', paramLabel: 'Month', paramValue: 'MN'),
        ];
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingAvailabilityTypes = false;
      });
    }
  }

  bool get _hasPostVisibilitySelection => _selectedViewCategory != null;
  bool get _hasAvailabilitySelection => _selectedAvailabilityType != null;

  void _togglePostVisibility(String value) {
    setState(() {
      _selectedViewCategory = value;
    });
  }

  void _toggleAvailability(String value) {
    setState(() {
      _selectedAvailabilityType = value;
    });
  }

  int? _selectedParamDetailId(
    List<GeneralParameterOption> options,
    String? selectedValue,
  ) {
    if (selectedValue == null) return null;

    for (final option in options) {
      if (option.paramValue == selectedValue || option.paramLabel == selectedValue) {
        return option.paramDetailId;
      }
    }

    return null;
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    setState(() {
      _hasTriedSubmit = false;
      _selectedCategory = null;
      _selectedDefendant = null;
      _selectedViewCategory = null;
      _uploadedMediaList.clear();
      _attachmentError = null;
      isMarkAsRead = false;
      _caseTitleController.clear();
      _descriptionController.clear();
    });
  }

  Future<void> _showAttachmentPicker() async {
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
                  'Select attachment source',
                  style: context.bold.copyWith(fontSize: 18),
                ),
                Space.vertical(12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.image_outlined),
                  title: const Text('Image from gallery'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImageFromGallery();
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.videocam_outlined),
                  title: const Text('Video from gallery'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickVideoFromGallery();
                  },
                ),
                // ListTile(
                //   contentPadding: EdgeInsets.zero,
                //   leading: const Icon(Icons.folder_open_outlined),
                //   title: const Text('Document from device'),
                //   onTap: () async {
                //     Navigator.pop(context);
                //     await _pickDocumentFromFiles();
                //   },
                // ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery);
      if (file == null || !mounted) return;
      final fileBytes = await file.readAsBytes();

      await _uploadSelectedFile(
        filePath: file.path,
        fileName: file.name,
        isImage: true,
        fileBytes: fileBytes,
      );
    } catch (e) {
      if (!mounted) return;
      AppAlert.showError(context, 'Failed to pick image from gallery: $e');
    }
  }

  Future<void> _pickVideoFromGallery() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickVideo(source: ImageSource.gallery);
      if (file == null || !mounted) return;
      final fileBytes = await file.readAsBytes();

      await _uploadSelectedFile(
        filePath: file.path,
        fileName: file.name,
        isImage: false,
        fileBytes: fileBytes,
      );
    } catch (e) {
      if (!mounted) return;
      AppAlert.showError(context, 'Failed to pick video from gallery: $e');
    }
  }

  Future<void> _uploadSelectedFile({
    required String filePath,
    required String fileName,
    required bool isImage,
    required Uint8List fileBytes,
  }) async {
    setState(() {
      _isUploadingAttachment = true;
      _attachmentError = null;
    });

    try {
      final accessToken = await const AuthStorage().readAccessToken();
      if (accessToken == null || accessToken.trim().isEmpty) {
        throw const ApiException('Session token not found');
      }

      const service = ApplicationCloudService();
      final UploadedMedia uploadedMedia = isImage
          ? await service.uploadImage(
              accessToken: accessToken,
              filePath: filePath,
              fileBytes: fileBytes,
              fileName: fileName,
            )
          : await service.uploadVideo(
              accessToken: accessToken,
              filePath: filePath,
              fileBytes: fileBytes,
              fileName: fileName,
            );

      if (!mounted) return;
      setState(() {
        _uploadedMediaList.add({
          'meta_id': uploadedMedia.metaId,
          'meta_type_id': uploadedMedia.metaTypeId,
          'meta_url': uploadedMedia.metaUrl,
          'fileName': fileName,
        });
      });

      AppAlert.showSuccess(
        context,
        '${isImage ? 'Image' : 'Video'} uploaded successfully',
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _attachmentError = e.message;
      });
      AppAlert.showError(context, e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _attachmentError = 'Failed to upload attachment';
      });
      AppAlert.showError(context, 'Failed to upload attachment: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isUploadingAttachment = false;
      });
    }
  }

  Future<void> _submitForm() async {
    setState(() {
      _hasTriedSubmit = true;
    });

    final isFormValid = _formKey.currentState?.validate() ?? false;
    final hasCustomValidationPassed =
        _hasPostVisibilitySelection &&
        _hasAvailabilitySelection &&
        isMarkAsRead;

    if (!isFormValid || !hasCustomValidationPassed) {
      return;
    }

    final userId = await const AuthStorage().readUserId();
    final accessToken = await const AuthStorage().readAccessToken();
    final caseCategoryId = _selectedParamDetailId(
      _categories,
      _selectedCategory,
    );
    final caseViewStatusId = _selectedParamDetailId(
      _viewCategories,
      _selectedViewCategory,
    );
    final caseAvailableStatusId = _selectedParamDetailId(
      _availabilityTypes,
      _selectedAvailabilityType,
    );
    final defendantUserId = _selectedDefendant == null
        ? null
        : int.tryParse(_selectedDefendant!);

    if (userId == null || accessToken == null || accessToken.trim().isEmpty) {
      AppAlert.showWarning(context, 'Session not found. Please login again.');
      return;
    }

    if (caseCategoryId == null ||
        caseViewStatusId == null ||
        caseAvailableStatusId == null ||
        defendantUserId == null) {
      AppAlert.showWarning(context, 'Please select all required options.');
      return;
    }

    setState(() {
      _isSubmittingCase = true;
    });

    final firstMedia = _uploadedMediaList.isNotEmpty ? _uploadedMediaList.first : null;
    final metaList = _uploadedMediaList.map((media) => {
      'meta_id': media['meta_id'],
      'meta_type_id': media['meta_type_id'],
      'meta_url': media['meta_url'],
      'is_active': 'Y',
    }).toList();

    try {
      final service = UserCaseService();
      await service.createUserCase(
        accessToken: accessToken,
        body: {
          'user_id': userId,
          'case_title': _caseTitleController.text.trim(),
          'case_description': _descriptionController.text.trim(),
          'case_category_id': caseCategoryId,
          'case_view_status_id': caseViewStatusId,
          'case_available_status_id': caseAvailableStatusId,
          'tag_defendent_user_id': defendantUserId,
          'meta_id': firstMedia?['meta_id'],
          'meta_type_id': firstMedia?['meta_type_id'],
          'meta_url': firstMedia?['meta_url'],
          'meta_list': metaList,
          'is_accept_terms': isMarkAsRead,
          // Using the description as resolution until a separate UI field exists.
          'case_resolution': _descriptionController.text.trim(),
        },
      );

      if (!mounted) return;
      AppAlert.showSuccess(context, 'Case uploaded successfully');
      _clearForm();
      widget.onCaseCreated?.call();
    } on ApiException catch (e) {
      if (!mounted) return;
      AppAlert.showError(context, e.message);
    } catch (e) {
      if (!mounted) return;
      AppAlert.showError(context, 'Failed to upload case: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmittingCase = false;
      });
    }
  }

  Widget _buildInlineError(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          message,
          style: context.normal.copyWith(color: kRedColor, fontSize: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 350;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: SearchBarHeader(),
        ),
        Space.vertical(14),

        // Create Case Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            "Create Case",
            style: context.bold.copyWith(fontSize: 24),
          ),
        ),

        // Form Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Space.vertical(20),
                    
                    // ✅ Top Caption
                    Text(
                      "Top Caption (Video Overlay)",
                      style: context.bold.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Space.vertical(8),
                    CustomTextField(
                      controller: _caseTitleController,
                      hintText: "Describe what the video is about",
                      hintTextColor: kDarkGreyColor,
                      validator: Validators.required,
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kBlackColor,
                      ),
                    ),
                    Space.vertical(16),
                    
                    // ✅ Bottom Description
                    Text(
                      "Bottom Description (Argument & Resolution)",
                      style: context.bold.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Space.vertical(8),
                    CustomTextField(
                      controller: _descriptionController,
                      hintText: "Present your argument and proposed resolution",
                      hintTextColor: kDarkGreyColor,
                      maxLine: 4,
                      validator: Validators.required,
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kBlackColor,
                      ),
                    ),
                    Space.vertical(16),
                    
                    // ✅ Tag User Defendants
                    Text(
                      "Tag user defendants",
                      style: context.bold.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Space.vertical(8),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Autocomplete<UserOption>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return const Iterable<UserOption>.empty();
                            }
                            return _defendants.where((user) =>
                                user.displayName.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                          },
                          displayStringForOption: (UserOption option) => option.displayName,
                          onSelected: (UserOption selection) {
                            setState(() {
                              _selectedDefendant = '${selection.userId}';
                            });
                          },
                          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                            return CustomTextField(
                              controller: textEditingController,
                              focusNode: focusNode,
                              hintText: _isLoadingDefendants ? "Loading defendants..." : "Search and tag defendant",
                              hintTextColor: kDarkGreyColor,
                              textStyle: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: kBlackColor,
                              ),
                            );
                          },
                          optionsViewBuilder: (context, onSelected, options) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 4.0,
                                child: SizedBox(
                                  width: constraints.biggest.width,
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    itemCount: options.length,
                                    itemBuilder: (context, index) {
                                      final option = options.elementAt(index);
                                      return ListTile(
                                        title: Text(
                                          option.displayName,
                                          style: TextStyle(color: AppColors.blackColor),
                                        ),
                                        onTap: () {
                                          onSelected(option);
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }
                    ),
                    if (_defendantLoadError != null)
                      _buildInlineError(_defendantLoadError!),
                    Space.vertical(16),
                    
                    // ✅ Write Resolution
                    Text(
                      "Write Resolution",
                      style: context.bold.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Space.vertical(8),
                    CustomTextField(
                      controller: _descriptionController,
                      hintText: "Write resolution what happened after win or loss",
                      hintTextColor: kDarkGreyColor,
                      maxLine: 4,
                      validator: Validators.required,
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kBlackColor,
                      ),
                    ),
                    Space.vertical(16),
                    
                    // ✅ Choose Category
                    Text(
                      "Choose category",
                      style: context.bold.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Space.vertical(8),
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
                      hint: _isLoadingCategories
                          ? "Loading categories..."
                          : "Select a Category",
                      screenWidth: screenWidth,
                      isSmallScreen: isSmallScreen,
                      isSearchable: true,
                      openSearchInPopup: false,
                      searchHintText: "Search category",
                      enabled:
                          !_isLoadingCategories && _categoryLoadError == null,
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                    ),
                    if (_categoryLoadError != null)
                      _buildInlineError(_categoryLoadError!),
                    if (_categoryLoadError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _loadCategories,
                            child: const Text('Retry'),
                          ),
                        ),
                      ),
                    Space.vertical(16),
                    
                    // ✅ You want to post? (Public/Private)
                    Text(
                      "You want to post?",
                      style: context.bold.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Space.vertical(8),
                    Row(
                      children: [
                        Checkbox(
                          value: _selectedViewCategory == 'Public',
                          onChanged: (value) {
                            setState(() {
                              _togglePostVisibility('Public');
                            });
                          },
                        ),
                        Text(
                          "Public",
                          style: context.bold.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Space.horizontal(12),
                        Checkbox(
                          value: _selectedViewCategory == 'Jury',
                          onChanged: (value) {
                            setState(() {
                              _togglePostVisibility('Jury');
                            });
                          },
                        ),
                        Text(
                          "Jury",
                          style: context.bold.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Space.horizontal(12),
                        Checkbox(
                          value: _selectedViewCategory == 'Private',
                          onChanged: (value) {
                            setState(() {
                              _togglePostVisibility('Private');
                            });
                          },
                        ),
                        Text(
                          "Private",
                          style: context.bold.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (_hasTriedSubmit && !_hasPostVisibilitySelection)
                      _buildInlineError('Please select post visibility'),
                    Space.vertical(16),
                    
                    // ✅ Post publicly available (24 Hours, Week, Month)
                    Text(
                      "Post publicly available",
                      style: context.bold.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Space.vertical(8),
                    if (_isLoadingAvailabilityTypes)
                      Text(
                        'Loading availability options...',
                        style: context.normal.copyWith(color: kDarkGreyColor),
                      )
                    else
                      Row(
                        children: [
                          Checkbox(
                            value: _selectedAvailabilityType == '24 hours',
                            onChanged: (value) {
                              setState(() {
                                _toggleAvailability('24 hours');
                              });
                            },
                          ),
                          Text(
                            "24 hours",
                            style: context.bold.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Space.horizontal(12),
                          Checkbox(
                            value: _selectedAvailabilityType == 'week',
                            onChanged: (value) {
                              setState(() {
                                _toggleAvailability('week');
                              });
                            },
                          ),
                          Text(
                            "week",
                            style: context.bold.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Space.horizontal(12),
                          Checkbox(
                            value: _selectedAvailabilityType == 'Month',
                            onChanged: (value) {
                              setState(() {
                                _toggleAvailability('Month');
                              });
                            },
                          ),
                          Text(
                            "Month",
                            style: context.bold.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    if (_availabilityTypeLoadError != null)
                      _buildInlineError(_availabilityTypeLoadError!),
                    if (_hasTriedSubmit && !_hasAvailabilitySelection)
                      _buildInlineError('Please select availability duration'),
                    Space.vertical(16),
                    
                    // ✅ Media Upload Section (Dotted Border)
                    DottedBorder(
                      options: RectDottedBorderOptions(
                        color: kPrimaryColor,
                        dashPattern: [5, 5],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: Column(
                            children: [
                              SvgPicture.asset(Assets.svgMusicIcon),
                              Space.vertical(15),
                              Text(
                                "Attached video and audio Max 3 min length",
                                textAlign: TextAlign.center,
                                style: context.normal.copyWith(
                                  color: kPrimaryColor,
                                  fontSize: 12,
                                ),
                              ),
                              if (_uploadedMediaList.isNotEmpty) ...[
                                Space.vertical(12),
                                ..._uploadedMediaList.map((media) {
                                  final isVideo = media['meta_type_id'] == 2;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isVideo ? Icons.videocam_outlined : Icons.image_outlined,
                                          color: kPrimaryColor,
                                          size: 20,
                                        ),
                                        Space.horizontal(8),
                                        Expanded(
                                          child: Text(
                                            media['fileName'] ?? 'Attachment',
                                            style: context.normal.copyWith(
                                              color: AppColors.blackColor,
                                              fontSize: 12,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: kRedColor, size: 20),
                                          onPressed: () {
                                            setState(() {
                                              _uploadedMediaList.remove(media);
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                              if (_attachmentError != null) ...[
                                Space.vertical(8),
                                Text(
                                  _attachmentError!,
                                  textAlign: TextAlign.center,
                                  style: context.normal.copyWith(
                                    color: kRedColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                              Space.vertical(15),
                              PrimaryButton(
                                height: 40,
                                isMainAxisSizeMin: true,
                                text: _isUploadingAttachment
                                    ? "Uploading..."
                                    : "Browse files",
                                buttonColor: kWhiteColor,
                                textColor: kBlackColor,
                                showBorder: true,
                                borderColor: kPrimaryColor,
                                processing: _isUploadingAttachment,
                                inactive: _isUploadingAttachment,
                                onPressed: _showAttachmentPicker,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Space.vertical(16),
                    
                    // ✅ Terms and Conditions
                    Text(
                      "Term and conditions",
                      style: context.bold.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Space.vertical(12),
                    Text(
                      "By uploading a file, you confirm that you own the rights to the content or have permission to share it. The app is not responsible for any unauthorized, harmful, or illegal files uploaded by users. Inappropriate files may be removed and accounts suspended.",
                      style: context.normal.copyWith(fontSize: 12),
                    ),
                    Space.vertical(12),
                    Row(
                      children: [
                        Checkbox(
                          value: isMarkAsRead,
                          onChanged: (value) {
                            setState(() {
                              isMarkAsRead = !isMarkAsRead;
                            });
                          },
                        ),
                        Expanded(
                          child: Text(
                            "I accept the terms and conditions",
                            style: context.normal.copyWith(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    if (_hasTriedSubmit && !isMarkAsRead)
                      _buildInlineError('Accept terms and condition first'),
                    Space.vertical(20),
                    
                    // ✅ Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            text: "Clear",
                            showBorder: true,
                            buttonColor: kWhiteColor,
                            borderColor: kGreyColor,
                            textColor: kBlackColor,
                            onPressed: _clearForm,
                          ),
                        ),
                        Space.horizontal(10),
                        Expanded(
                          child: PrimaryButton(
                            text: "Upload Case",
                            processing: _isSubmittingCase,
                            inactive: _isSubmittingCase,
                            onPressed: _submitForm,
                          ),
                        ),
                      ],
                    ),
                    Space.vertical(20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
