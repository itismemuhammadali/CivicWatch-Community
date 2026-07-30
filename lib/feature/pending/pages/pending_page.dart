import 'package:cctv_app/core/components/search_bar_header.dart';
import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/network/api_exception.dart';
import 'package:cctv_app/core/network/models/app_notification_item.dart';
import 'package:cctv_app/core/network/models/pending_case.dart';
import 'package:cctv_app/core/network/services/user_case_service.dart';
import 'package:cctv_app/core/storage/auth_storage.dart';
import 'package:cctv_app/core/utils/assets.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/feature/pending/pages/pending_case_response_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PendingPage extends StatefulWidget {
  const PendingPage({super.key});

  @override
  State<PendingPage> createState() => _PendingPageState();
}

class _PendingPageState extends State<PendingPage> {
  bool _isLoading = true;
  String? _error;
  List<PendingCase> _pendingCases = const [];
  final Set<int> _deletingCaseIds = <int>{};
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadPendingCases();
  }

  Future<void> _loadPendingCases() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final storage = const AuthStorage();
      final accessToken = await storage.readAccessToken();
      final userId = await storage.readUserId();
      _currentUserId = userId;

      if (accessToken == null || accessToken.trim().isEmpty || userId == null) {
        throw const ApiException('Session not found');
      }

      final cases = await UserCaseService().getPendingCases(
        accessToken: accessToken,
        userId: userId,
      );

      if (!mounted) return;
      setState(() {
        _pendingCases = cases;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load pending cases';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePendingCase(PendingCase pendingCase) async {
    final caseId = pendingCase.caseId;
    if (_deletingCaseIds.contains(caseId)) return;

    setState(() {
      _deletingCaseIds.add(caseId);
    });

    try {
      final accessToken = await const AuthStorage().readAccessToken();
      if (accessToken == null || accessToken.trim().isEmpty) {
        throw const ApiException('Session token not found');
      }

      await UserCaseService().deleteUserCase(
        accessToken: accessToken,
        caseId: caseId,
      );

      if (!mounted) return;
      setState(() {
        _pendingCases =
            _pendingCases.where((item) => item.caseId != caseId).toList();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _deletingCaseIds.remove(caseId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 16.0, right: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchBarHeader(),
          Space.vertical(12),
          Text("Case Pending", style: context.bold.copyWith(fontSize: 24)),
          Space.vertical(20),
          Expanded(
            child: _buildBody(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: context.normal.copyWith(color: kRedColor)),
            Space.vertical(8),
            TextButton(
              onPressed: _loadPendingCases,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_pendingCases.isEmpty) {
      return Center(
        child: Text(
          "No pending cases",
          style: context.normal.copyWith(color: kDarkGreyColor),
        ),
      );
    }

    final leftColumnCases = <PendingCase>[];
    final rightColumnCases = <PendingCase>[];

    for (var i = 0; i < _pendingCases.length; i++) {
      if (i % 2 == 0) {
        leftColumnCases.add(_pendingCases[i]);
      } else {
        rightColumnCases.add(_pendingCases[i]);
      }
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: leftColumnCases
                    .map((caseItem) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildPendingCard(context, caseItem),
                        ))
                    .toList(),
              ),
            ),
            if (rightColumnCases.isNotEmpty) ...[
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: rightColumnCases
                      .map((caseItem) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildPendingCard(context, caseItem),
                          ))
                      .toList(),
                ),
              ),
            ]
          ],
        ),
        Space.vertical(20),
      ],
    );
  }

  Widget _buildPendingCard(BuildContext context, PendingCase pendingCase) {
    final title = pendingCase.caseTitle.trim().isNotEmpty
        ? pendingCase.caseTitle
        : 'Case #${pendingCase.caseId}';
    final description = pendingCase.caseDescription.trim();
    final date = pendingCase.caseCreatedAt != null
        ? pendingCase.caseCreatedAt!.split('T').first
        : 'Recently';
    final imageUrl = pendingCase.metaList.isNotEmpty
        ? pendingCase.metaList.first.metaUrl
        : pendingCase.applicationMeta?.metaUrl;

    return GestureDetector(
      onTap: () {
        if (_currentUserId != null && pendingCase.tagDefendentUserId == _currentUserId) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PendingCaseResponsePage(caseId: pendingCase.caseId),
            ),
          );
        } else {
          // Creator tapped it, maybe show a snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Waiting for tagged user to respond...'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: kWhiteColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
          BoxShadow(
            color: kBlackColor.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: _buildCaseImage(imageUrl, height: 100),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.bold.copyWith(fontSize: 14)),
                if (description.isNotEmpty) ...[
                  Space.vertical(4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.normal.copyWith(
                      fontSize: 11,
                      color: kDarkGreyColor,
                    ),
                  ),
                ],
                Space.vertical(6),
                Text(
                  date,
                  style: context.normal.copyWith(
                    fontSize: 10,
                    color: kDarkGreyColor,
                  ),
                ),
                Space.vertical(8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // Remind logic
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Reminder sent for $title'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0085FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.notifications_active,
                                color: kWhiteColor,
                                size: 14,
                              ),
                              Space.horizontal(4),
                              Text(
                                'Remind',
                                style: context.semiBold.copyWith(
                                  fontSize: 11,
                                  color: kWhiteColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Space.horizontal(6),
                    GestureDetector(
                      onTap: () => _deletePendingCase(pendingCase),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: kGreyColor),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        child: _deletingCaseIds.contains(pendingCase.caseId)
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: kDarkGreyColor,
                                ),
                              )
                            : SvgPicture.asset(
                                Assets.svgDeleteIcon,
                                width: 14,
                                height: 14,
                                colorFilter: const ColorFilter.mode(
                                  kDarkGreyColor,
                                  BlendMode.srcIn,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildCaseImage(String? imagePath, {required double height}) {
    if (imagePath == null || imagePath.isEmpty) {
      return Container(
        width: double.infinity,
        height: height,
        color: kLightGreyColor,
        child: const Icon(Icons.image_not_supported_outlined),
      );
    }
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: double.infinity,
          height: height,
          color: kLightGreyColor,
          child: const Icon(Icons.image_not_supported_outlined),
        ),
      );
    }
    return Image.asset(
      imagePath,
      width: double.infinity,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: double.infinity,
        height: height,
        color: kLightGreyColor,
        child: const Icon(Icons.image_not_supported_outlined),
      ),
    );
  }
}
