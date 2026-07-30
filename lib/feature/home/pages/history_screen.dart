import 'package:cctv_app/core/components/custom_textfield.dart';
import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/network/api_exception.dart';
import 'package:cctv_app/core/network/models/application_alert.dart';
import 'package:cctv_app/core/network/services/admin_control_service.dart';
import 'package:cctv_app/core/storage/auth_storage.dart';
import 'package:cctv_app/core/utils/app_date_time.dart';
import 'package:cctv_app/core/utils/assets.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();
  final AdminControlService _adminControlService = AdminControlService();

  bool _isLoading = true;
  String? _error;
  List<ApplicationAlert> _alerts = const [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_focusNode);
      }
    });
    _loadHistory();
  }

  @override
  void dispose() {
    _controller.removeListener(_handleSearchChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final storage = const AuthStorage();
      final accessToken = await storage.readAccessToken();
      final userId = await storage.readUserId();

      if (accessToken == null || accessToken.trim().isEmpty) {
        throw const ApiException('Session token not found');
      }
      if (userId == null) {
        throw const ApiException('Session user not found');
      }

      final alerts = await _adminControlService.getAllApplicationAlerts(
        accessToken: accessToken,
        onlyActive: true,
      );

      if (!mounted) return;
      setState(() {
        _alerts = alerts.where((alert) => alert.createdBy == userId).toList();
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load alert history';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<ApplicationAlert> get _filteredAlerts {
    final query = _controller.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _alerts;
    }

    return _alerts.where((alert) {
      return alert.alertNote.toLowerCase().contains(query) ||
          alert.category.toLowerCase().contains(query) ||
          '${alert.alertId}'.contains(query);
    }).toList();
  }

  String _formatDate(String? value) {
    final formatted = AppDateTime.formatShortDateTime(value);
    return formatted.trim().isEmpty ? '-' : formatted;
  }

  String _categoryLabel(String category) {
    switch (category.trim().toUpperCase()) {
      case 'A':
        return 'Announcement';
      case 'U':
        return 'Update';
      default:
        return category.trim().isEmpty ? 'General' : category.trim();
    }
  }

  Color _categoryColor(String category) {
    switch (category.trim().toUpperCase()) {
      case 'A':
        return kPrimaryColor;
      case 'U':
        return kRedColor;
      default:
        return kDarkGreyColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredAlerts = _filteredAlerts;

    return Scaffold(
      backgroundColor: kWhiteColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              Row(
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Icon(Icons.arrow_back, color: kBlackColor),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  Space.horizontal(20),
                  Expanded(
                    child: CustomTextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      topPadding: 10,
                      bottomPadding: 10,
                      hintText: '',
                      prefix: const Icon(Icons.search, color: kDarkGreyColor),
                      hintTextColor: kDarkGreyColor,
                    ),
                  ),
                ],
              ),
              Space.vertical(20),
              Expanded(
                child: _buildBody(filteredAlerts),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(List<ApplicationAlert> filteredAlerts) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: context.normal.copyWith(color: kRedColor),
            ),
            Space.vertical(8),
            TextButton(onPressed: _loadHistory, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_alerts.isEmpty) {
      return Center(
        child: Text(
          'No alert history found for this user',
          style: context.normal.copyWith(color: kDarkGreyColor),
        ),
      );
    }

    if (filteredAlerts.isEmpty) {
      return Center(
        child: Text(
          'No matching alerts found',
          style: context.normal.copyWith(color: kDarkGreyColor),
        ),
      );
    }

    return ListView.separated(
      itemCount: filteredAlerts.length,
      separatorBuilder: (_, _) => Space.vertical(12),
      itemBuilder: (context, index) {
        final alert = filteredAlerts[index];
        final categoryColor = _categoryColor(alert.category);

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kWhiteColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kGreyColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  Assets.svgHistoryIcon,
                  colorFilter: ColorFilter.mode(
                    categoryColor,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              Space.horizontal(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _categoryLabel(alert.category),
                      style: context.bold.copyWith(fontSize: 14),
                    ),
                    Space.vertical(4),
                    Text(
                      alert.alertNote,
                      style: context.normal.copyWith(fontSize: 13, color: kDarkGreyColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Space.vertical(4),
                    Text(
                      _formatDate(alert.createdAt),
                      style: context.normal.copyWith(fontSize: 12, color: kGreyColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
