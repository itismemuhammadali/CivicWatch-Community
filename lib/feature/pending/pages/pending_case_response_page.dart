import 'dart:async';
import 'dart:typed_data';

import 'package:cctv_app/core/components/app_alert.dart';
import 'package:cctv_app/core/components/primary_button.dart';
import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/components/plain_selection_widget.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/network/models/pending_case.dart';
import 'package:cctv_app/core/network/models/uploaded_media.dart';
import 'package:cctv_app/core/network/services/application_cloud_service.dart';
import 'package:cctv_app/core/network/services/user_defendent_service.dart';
import 'package:cctv_app/core/firebase/firestore_service.dart';
import 'package:cctv_app/core/storage/auth_storage.dart';
import 'package:cctv_app/core/utils/app_date_time.dart';
import 'package:cctv_app/core/utils/assets.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/core/utils/validators.dart';
import 'package:cctv_app/feature/bottomNavBar/user_bottom_nav_bar.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

class PendingCaseResponsePage extends StatefulWidget {
  final PendingCase? pendingCase;

  /// Fallback parameters when navigating from home screen mock data.
  final int? caseId;
  final String? caseTitle;
  final String? mediaUrl;
  final bool isMediaImage;
  final String? createdAt;

  const PendingCaseResponsePage({
    super.key,
    this.pendingCase,
    this.caseId,
    this.caseTitle,
    this.mediaUrl,
    this.isMediaImage = false,
    this.createdAt,
  });

  @override
  State<PendingCaseResponsePage> createState() =>
      _PendingCaseResponsePageState();
}

class _PendingCaseResponsePageState extends State<PendingCaseResponsePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _resolutionController = TextEditingController();
  VideoPlayerController? _videoController;
  Future<void>? _videoInitialization;
  VoidCallback? _videoListener;
  bool _isUploadingAttachment = false;
  bool _isSubmittingResponse = false;
  bool _isAcceptTerms = false;
  bool _hasTriedSubmit = false;
  String? _selectedAttachmentName;
  String? _attachmentError;
  int? _attachmentMetaId;
  String? _attachmentMetaUrl;
  late String _currentTime;
  Timer? _timeTimer;
  bool _isLoadingCase = false;
  PendingCase? _dynamicPendingCase;

  int? get _resolvedCaseId =>
      _dynamicPendingCase?.caseId ?? widget.pendingCase?.caseId ?? widget.caseId;

  String get _resolvedTitle {
    final pc = _dynamicPendingCase ?? widget.pendingCase;
    if (pc != null) {
      return pc.caseTitle.trim().isEmpty
          ? 'Untitled case'
          : pc.caseTitle;
    }
    return widget.caseTitle ?? 'Untitled case';
  }

  String get _resolvedMediaUrl {
    final pc = _dynamicPendingCase ?? widget.pendingCase;
    if (pc != null) {
      return pc.applicationMeta?.metaUrl?.trim() ?? '';
    }
    return widget.mediaUrl?.trim() ?? '';
  }

  bool get _resolvedHasMedia {
    final pc = _dynamicPendingCase ?? widget.pendingCase;
    if (pc != null) {
      return pc.hasMedia;
    }
    return _resolvedMediaUrl.isNotEmpty;
  }

  bool get _resolvedIsImage {
    final pc = _dynamicPendingCase ?? widget.pendingCase;
    if (pc != null) {
      return pc.isImage;
    }
    return widget.isMediaImage;
  }

  String get _resolvedCreatedAt {
    final pc = _dynamicPendingCase ?? widget.pendingCase;
    if (pc != null) {
      return AppDateTime.formatShortDateTime(
        pc.caseCreatedAt,
      );
    }
    return widget.createdAt ?? '';
  }

  @override
  void initState() {
    super.initState();
    _currentTime = _formatCurrentTime();
    _timeTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() {
        _currentTime = _formatCurrentTime();
      });
    });

    _loadCaseDetails();
  }

  Future<void> _loadCaseDetails() async {
    if (widget.pendingCase == null && widget.caseId != null) {
      setState(() {
        _isLoadingCase = true;
      });
      final caseData = await FirestoreDataService().getPendingCaseById(widget.caseId!);
      if (mounted) {
        setState(() {
          _dynamicPendingCase = caseData;
          _isLoadingCase = false;
        });
        _initVideoController();
      }
    } else {
      _initVideoController();
    }
  }

  void _initVideoController() {
    final url = _resolvedMediaUrl;
    if (url.isNotEmpty && !_resolvedIsImage) {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      _videoController = controller;
      _videoListener = () {
        if (!mounted) return;
        setState(() {});
      };
      controller.addListener(_videoListener!);
      _videoInitialization = controller.initialize().then((_) {
        if (!mounted) return;
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timeTimer?.cancel();
    _resolutionController.dispose();
    if (_videoController != null && _videoListener != null) {
      _videoController!.removeListener(_videoListener!);
    }
    _videoController?.dispose();
    super.dispose();
  }

  String _formatCurrentTime() {
    final now = DateTime.now();
    final hour =
        now.hour == 0 ? 12 : now.hour > 12 ? now.hour - 12 : now.hour;
    final minute = now.minute.toString().padLeft(2, '0');
    final suffix = now.hour >= 12 ? 'PM' : 'AM';
    return '${now.hour.toString().padLeft(2, '0')}:$minute now ($hour:$minute $suffix)';
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
        throw Exception('Session token not found');
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
        _selectedAttachmentName = fileName;
        _attachmentMetaId = uploadedMedia.metaId;
        _attachmentMetaUrl = uploadedMedia.metaUrl;
      });

      AppAlert.showSuccess(
        context,
        '${isImage ? 'Image' : 'Video'} uploaded successfully',
      );
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

  void _clearForm() {
    setState(() {
      _formKey.currentState?.reset();
      _resolutionController.clear();
      _isAcceptTerms = false;
      _hasTriedSubmit = false;
      _selectedAttachmentName = null;
      _attachmentError = null;
      _attachmentMetaId = null;
      _attachmentMetaUrl = null;
    });
  }

  Future<void> _submitResponse() async {
    setState(() {
      _hasTriedSubmit = true;
    });

    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid || !_isAcceptTerms) {
      return;
    }

    final caseId = _resolvedCaseId;
    final defendentId = await const AuthStorage().readUserId();
    final accessToken = await const AuthStorage().readAccessToken();

    if (caseId == null ||
        defendentId == null ||
        accessToken == null ||
        accessToken.trim().isEmpty) {
      print('DEBUG _submitResponse MISSING: caseId=$caseId, defendentId=$defendentId, hasAccessToken=${accessToken != null && accessToken.isNotEmpty}');
      if (!mounted) return;
      AppAlert.showWarning(context, 'Missing case or session information');
      return;
    }

    setState(() {
      _isSubmittingResponse = true;
    });

    try {
      final service = FirestoreDataService();
      await service.approveAndPublishCase(
        caseId: caseId,
        defendentId: defendentId,
        caseResolution: _resolutionController.text.trim(),
        metaUrl: _attachmentMetaUrl,
        metaId: _attachmentMetaId,
      );

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const UserBottomNavBar()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      AppAlert.showError(context, 'Failed to submit response: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmittingResponse = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhiteColor,
      appBar: AppBar(
        backgroundColor: kWhiteColor,
        centerTitle: true,
        leading: const BackButton(),
        title: Text('Response', style: context.bold.copyWith(fontSize: 18)),
      ),
      body: _isLoadingCase
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.only(top: 10, left: 16.0, right: 16.0),
              child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attached video',
                  style: context.normal.copyWith(fontSize: 16),
                ),
                Space.vertical(10),
                if (_resolvedHasMedia)
                  _CaseMediaPreview(
                    mediaUrl: _resolvedMediaUrl,
                    isImage: _resolvedIsImage,
                    controller: _videoController,
                    initialization: _videoInitialization,
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: double.infinity,
                      height: 220,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: Image.asset(
                              'assets/images/case_thumbnail.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: kLightGreyColor,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.videocam_off_outlined,
                                  size: 48,
                                  color: kDarkGreyColor,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            decoration: const BoxDecoration(
                              color: kPrimaryColor,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(10),
                            child: const Icon(
                              Icons.play_arrow,
                              color: kWhiteColor,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Space.vertical(20),
                Text(
                  'Responds',
                  style: context.normal.copyWith(fontSize: 16),
                ),
                Space.vertical(10),
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
                            'Attached video and audio Max 3 min length',
                            style: context.normal.copyWith(
                              color: kPrimaryColor,
                            ),
                          ),
                          if (_selectedAttachmentName != null) ...[
                            Space.vertical(12),
                            Text(
                              _selectedAttachmentName!,
                              textAlign: TextAlign.center,
                              style: context.normal.copyWith(
                                color: kBlackColor,
                              ),
                            ),
                          ],
                          if (_attachmentMetaId != null) ...[
                            Space.vertical(8),
                            Text(
                              'Meta ID: $_attachmentMetaId',
                              textAlign: TextAlign.center,
                              style: context.normal.copyWith(
                                color: kPrimaryColor,
                              ),
                            ),
                          ],
                          if (_attachmentError != null) ...[
                            Space.vertical(8),
                            Text(
                              _attachmentError!,
                              textAlign: TextAlign.center,
                              style: context.normal.copyWith(color: kRedColor),
                            ),
                          ],
                          Space.vertical(15),
                          PrimaryButton(
                            height: 40,
                            isMainAxisSizeMin: true,
                            text: _isUploadingAttachment
                                ? 'Uploading...'
                                : 'Browse files',
                            buttonColor: kWhiteColor,
                            textColor: kBlackColor,
                            showBorder: true,
                            prefixIcon: const Icon(Icons.attach_file),
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
                Space.vertical(12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _currentTime,
                    style: context.normal.copyWith(fontSize: 14),
                  ),
                ),
                Space.vertical(16),
                Text(
                  'Write Resolution',
                  style: context.normal.copyWith(fontSize: 16),
                ),
                Space.vertical(8),
                TextFormField(
                  controller: _resolutionController,
                  maxLines: 5,
                  validator: Validators.required,
                  decoration: InputDecoration(
                    hintText: 'Write resolution what happed after win or loss',
                    hintStyle: context.normal.copyWith(
                      color: kDarkGreyColor,
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: kGreyColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: kGreyColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: kPrimaryColor),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                Space.vertical(20),
                Text(
                  'Term and conditions',
                  style: context.bold.copyWith(fontSize: 18),
                ),
                Space.vertical(10),
                Text(
                  "By uploading a file, you confirm that you own the rights to the content or have permission to share it. The app is not responsible for any unauthorized, harmful, or illegal files uploaded by users. Inappropriate files may be removed and accounts suspended.",
                  style: context.normal.copyWith(fontSize: 14),
                ),
                Space.vertical(12),
                PlainSelectionWidget(
                  onChange: () {
                    setState(() {
                      _isAcceptTerms = !_isAcceptTerms;
                    });
                  },
                  isSelected: _isAcceptTerms,
                  title: "Mark as read",
                  subTitle: "",
                ),
                if (_hasTriedSubmit && !_isAcceptTerms)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'You must accept the terms and conditions to submit.',
                      style: context.normal.copyWith(color: kRedColor, fontSize: 12),
                    ),
                  ),
                Space.vertical(16),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        text: 'Clear',
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
                        text: 'Submit case',
                        processing: _isSubmittingResponse,
                        inactive: _isSubmittingResponse,
                        onPressed: _submitResponse,
                      ),
                    ),
                  ],
                ),
                Space.vertical(40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CaseMediaPreview extends StatelessWidget {
  final String mediaUrl;
  final bool isImage;
  final VideoPlayerController? controller;
  final Future<void>? initialization;

  const _CaseMediaPreview({
    required this.mediaUrl,
    required this.isImage,
    required this.controller,
    required this.initialization,
  });

  @override
  Widget build(BuildContext context) {
    if (isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          height: 220,
          color: kBlackColor.withValues(alpha: 0.06),
          child: Image.network(
            mediaUrl,
            fit: BoxFit.contain,
            width: double.infinity,
            height: 220,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
      );
    }

    if (controller == null || initialization == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<void>(
      future: initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _VideoPlaceholder(
            child: const CircularProgressIndicator(color: kWhiteColor),
          );
        }

        if (!controller!.value.isInitialized) {
          return const SizedBox.shrink();
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: double.infinity,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: controller!.value.size.width == 0
                          ? 16
                          : controller!.value.size.width,
                      height: controller!.value.size.height == 0
                          ? 9
                          : controller!.value.size.height,
                      child: VideoPlayer(controller!),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (controller!.value.isPlaying) {
                          controller!.pause();
                        } else {
                          controller!.play();
                        }
                      },
                      child: controller!.value.isPlaying
                          ? const SizedBox.shrink()
                          : AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: 1,
                              child: Container(
                                color: Colors.black.withValues(alpha: 0.25),
                                alignment: Alignment.center,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: kPrimaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(10),
                                  child: const Icon(
                                    Icons.play_arrow,
                                    color: kWhiteColor,
                                    size: 40,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _VideoPlaceholder extends StatelessWidget {
  final Widget child;

  const _VideoPlaceholder({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        height: 220,
        color: kBlackColor.withValues(alpha: 0.75),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
