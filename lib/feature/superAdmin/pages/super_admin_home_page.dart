import 'package:cctv_app/core/components/custom_textfield.dart';
import 'package:cctv_app/core/components/notification_icon_button.dart';
import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/components/app_alert.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/network/api_exception.dart';
import 'package:cctv_app/core/network/models/user_profile.dart';
import 'package:cctv_app/core/network/services/dashboard_service.dart';
import 'package:cctv_app/core/network/services/user_service.dart';
import 'package:cctv_app/core/storage/auth_storage.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/feature/profile/pages/profile_page.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SuperAdminHomePage extends StatefulWidget {
  const SuperAdminHomePage({super.key});

  @override
  State<SuperAdminHomePage> createState() => _SuperAdminHomePageState();
}

class _SuperAdminHomePageState extends State<SuperAdminHomePage> {
  static const _tabs = ['Daily', 'Weekly', 'Monthly', 'Year'];
  int selectedTab = 3;
  bool _isLoadingSummary = false;
  String? _summaryError;
  int? _latestRegisterCount;
  int? _activeUserCount;
  bool _isLoadingChart = false;
  String? _chartError;
  List<_ChartPoint> _chartPoints = const [];
  bool _isLoadingRecentAdmins = false;
  String? _recentAdminsError;
  List<UserProfile> _recentAdmins = const [];
  final Set<int> _deletingAdminIds = <int>{};

  @override
  void initState() {
    super.initState();
    _loadSummary();
    _loadChart();
    _loadRecentAdmins();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoadingSummary = true;
      _summaryError = null;
    });

    try {
      final accessToken = await const AuthStorage().readAccessToken();
      if (accessToken == null || accessToken.trim().isEmpty) {
        throw const ApiException('Session token not found');
      }

      final dashboardService = DashboardService();
      final latestRegisterCount = await dashboardService
          .getLatestRegistrationCount(accessToken: accessToken);
      final activeUserCount = await dashboardService.getActiveUserCount(
        accessToken: accessToken,
      );

      if (!mounted) return;
      setState(() {
        _latestRegisterCount = latestRegisterCount;
        _activeUserCount = activeUserCount;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _summaryError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _summaryError = 'Failed to load dashboard summary';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSummary = false;
        });
      }
    }
  }

  Future<void> _loadChart() async {
    setState(() {
      _isLoadingChart = true;
      _chartError = null;
    });

    // Mock chart data
    _chartPoints = [
      _ChartPoint(label: '2021', value: 1330),
      _ChartPoint(label: '2022', value: 4370),
      _ChartPoint(label: '2023', value: 8800),
      _ChartPoint(label: '2024', value: 16330),
      _ChartPoint(label: '2025', value: 25660),
    ];

    setState(() {
      _isLoadingChart = false;
    });
  }

  Future<void> _loadRecentAdmins() async {
    setState(() {
      _isLoadingRecentAdmins = true;
      _recentAdminsError = null;
    });

    try {
      final token = await const AuthStorage().readAccessToken() ?? '';
      final currentUserId = await const AuthStorage().readUserId();
      var admins = await const UserService().getAllRecentAdmins(
        accessToken: token,
        limit: 10,
      );
      
      if (currentUserId != null) {
        admins = admins.where((admin) => admin.userId != currentUserId).toList();
      }

      if (!mounted) return;
      setState(() {
        _recentAdmins = admins.take(3).toList();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _recentAdminsError = 'Failed to load recent admins';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRecentAdmins = false;
        });
      }
    }
  }

  Future<void> _deleteAdmin(UserProfile admin) async {
    final userId = admin.userId;
    if (userId <= 0) {
      AppAlert.showError(context, 'Invalid user id');
      return;
    }
    if (_deletingAdminIds.contains(userId)) return;

    setState(() {
      _deletingAdminIds.add(userId);
    });

    try {
      final accessToken = await const AuthStorage().readAccessToken();
      if (accessToken == null || accessToken.trim().isEmpty) {
        throw const ApiException('Session token not found');
      }

      await const UserService().deleteUser(
        accessToken: accessToken,
        userId: userId,
      );

      if (!mounted) return;
      AppAlert.showSuccess(context, 'Admin deleted successfully');
      await _loadRecentAdmins();
    } on ApiException catch (e) {
      if (!mounted) return;
      AppAlert.showError(context, e.message);
    } catch (e) {
      if (!mounted) return;
      AppAlert.showError(context, 'Failed to delete admin: $e');
    } finally {
      if (mounted) {
        setState(() {
          _deletingAdminIds.remove(userId);
        });
      }
    }
  }

  Future<void> _confirmDeleteAdmin(UserProfile admin) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: kWhiteColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: const Text('Are you sure?'),
          content: const Text('Want to delete admin profile?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await _deleteAdmin(admin);
    }
  }

  String _formatSummaryValue(int? value) {
    if (_isLoadingSummary) return '...';
    if (_summaryError != null) return '-';
    return (value ?? 0).toString();
  }

  DateTimeRange _dateRangeForTab(int tabIndex) {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day);

    switch (tabIndex) {
      case 0:
        return DateTimeRange(
          start: end.subtract(const Duration(days: 6)),
          end: end,
        );
      case 1:
        return DateTimeRange(
          start: end.subtract(const Duration(days: 55)),
          end: end,
        );
      case 2:
        return DateTimeRange(
          start: DateTime(end.year, end.month - 11, 1),
          end: end,
        );
      case 3:
      default:
        return DateTimeRange(start: DateTime(end.year - 4, 1, 1), end: end);
    }
  }

  List<_ChartPoint> _buildChartPoints(
    List<DashboardUserAnalysisEntry> entries,
    DateTimeRange range,
    int tabIndex,
  ) {
    final normalizedEntries = entries
        .map(
          (entry) => DashboardUserAnalysisEntry(
            date: DateTime(entry.date.year, entry.date.month, entry.date.day),
            count: entry.count,
          ),
        )
        .toList();

    switch (tabIndex) {
      case 0:
        return _buildDailyPoints(normalizedEntries, range);
      case 1:
        return _buildWeeklyPoints(normalizedEntries, range);
      case 2:
        return _buildMonthlyPoints(normalizedEntries, range);
      case 3:
      default:
        return _buildYearlyPoints(normalizedEntries, range);
    }
  }

  List<_ChartPoint> _buildDailyPoints(
    List<DashboardUserAnalysisEntry> entries,
    DateTimeRange range,
  ) {
    final totals = <DateTime, int>{};
    for (final entry in entries) {
      totals.update(
        entry.date,
        (value) => value + entry.count,
        ifAbsent: () => entry.count,
      );
    }

    final points = <_ChartPoint>[];
    for (
      var day = range.start;
      !day.isAfter(range.end);
      day = day.add(const Duration(days: 1))
    ) {
      points.add(
        _ChartPoint(label: _formatDayLabel(day), value: (totals[day] ?? 0).toDouble()),
      );
    }
    return points;
  }

  List<_ChartPoint> _buildWeeklyPoints(
    List<DashboardUserAnalysisEntry> entries,
    DateTimeRange range,
  ) {
    DateTime weekStart(DateTime date) {
      final normalized = DateTime(date.year, date.month, date.day);
      return normalized.subtract(Duration(days: normalized.weekday - 1));
    }

    final totals = <DateTime, int>{};
    for (final entry in entries) {
      final start = weekStart(entry.date);
      totals.update(start, (value) => value + entry.count, ifAbsent: () => entry.count);
    }

    final points = <_ChartPoint>[];
    var cursor = weekStart(range.start);
    final last = weekStart(range.end);

    while (!cursor.isAfter(last)) {
      points.add(
        _ChartPoint(label: _formatDayLabel(cursor), value: (totals[cursor] ?? 0).toDouble()),
      );
      cursor = cursor.add(const Duration(days: 7));
    }
    return points;
  }

  List<_ChartPoint> _buildMonthlyPoints(
    List<DashboardUserAnalysisEntry> entries,
    DateTimeRange range,
  ) {
    DateTime monthStart(DateTime date) => DateTime(date.year, date.month, 1);

    final totals = <DateTime, int>{};
    for (final entry in entries) {
      final start = monthStart(entry.date);
      totals.update(start, (value) => value + entry.count, ifAbsent: () => entry.count);
    }

    final points = <_ChartPoint>[];
    var cursor = monthStart(range.start);
    final last = monthStart(range.end);

    while (!cursor.isAfter(last)) {
      points.add(
        _ChartPoint(label: _formatMonthLabel(cursor), value: (totals[cursor] ?? 0).toDouble()),
      );
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }
    return points;
  }

  List<_ChartPoint> _buildYearlyPoints(
    List<DashboardUserAnalysisEntry> entries,
    DateTimeRange range,
  ) {
    DateTime yearStart(DateTime date) => DateTime(date.year, 1, 1);

    final totals = <DateTime, int>{};
    for (final entry in entries) {
      final start = yearStart(entry.date);
      totals.update(start, (value) => value + entry.count, ifAbsent: () => entry.count);
    }

    final points = <_ChartPoint>[];
    var cursor = yearStart(range.start);
    final last = yearStart(range.end);
    while (!cursor.isAfter(last)) {
      points.add(
        _ChartPoint(label: cursor.year.toString(), value: (totals[cursor] ?? 0).toDouble()),
      );
      cursor = DateTime(cursor.year + 1, 1, 1);
    }
    return points;
  }

  String _formatDayLabel(DateTime date) => '${_two(date.month)}/${_two(date.day)}';
  String _formatMonthLabel(DateTime date) => _two(date.month);
  String _two(int value) => value.toString().padLeft(2, '0');

  String _formatRecentAdminTime(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Recently added';
    }

    final parsed = DateTime.tryParse(value)?.toLocal();
    if (parsed == null) {
      return value.replaceFirst('T', ' ');
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final month = months[parsed.month - 1];
    final hour = parsed.hour == 0
        ? 12
        : parsed.hour > 12
        ? parsed.hour - 12
        : parsed.hour;
    final minute = parsed.minute.toString().padLeft(2, '0');
    final suffix = parsed.hour >= 12 ? 'pm' : 'am';
    return '$month ${parsed.day}, ${parsed.year} $hour:$minute $suffix';
  }

  Widget _buildRecentAdminsSection() {
    if (_isLoadingRecentAdmins) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_recentAdminsError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _recentAdminsError!,
              style: const TextStyle(color: kDarkGreyColor),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadRecentAdmins,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_recentAdmins.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No recent admins found',
          style: TextStyle(color: kDarkGreyColor),
        ),
      );
    }

    return Column(
      children: _recentAdmins
          .take(3)
          .map(
            (admin) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RecentAdminCard(
                admin: admin,
                timeLabel: _formatRecentAdminTime(admin.createdAt),
                isDeleting: _deletingAdminIds.contains(admin.userId),
                onMenuSelected: (value) {
                  if (value == 'remove') {
                    _confirmDeleteAdmin(admin);
                  }
                },
              ),
            ),
          )
          .toList(),
    );
  }

  double _maxChartValue(List<_ChartPoint> points) {
    var maxValue = 0.0;
    for (final point in points) {
      if (point.value > maxValue) maxValue = point.value;
    }
    if (maxValue <= 0) return 1;
    return maxValue + (maxValue * 0.15);
  }

  Widget _buildChartBody() {
    if (_isLoadingChart) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_chartError != null) {
      return Center(
        child: Text(
          _chartError!,
          style: const TextStyle(fontSize: 12, color: kDarkGreyColor),
        ),
      );
    }

    if (_chartPoints.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(fontSize: 12, color: kDarkGreyColor),
        ),
      );
    }

    final maxValue = _maxChartValue(_chartPoints);
    final interval = maxValue <= 1 ? 1.0 : (maxValue / 5).ceilToDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceBetween,
        maxY: maxValue,
        minY: 0,
        gridData: FlGridData(
          show: true,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (value) => FlLine(
            color: kGreyColor.withValues(alpha: 0.7),
            strokeWidth: 1,
          ),
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              interval: interval,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10, color: kDarkGreyColor),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= _chartPoints.length) {
                  return const SizedBox.shrink();
                }
                final skip = _chartPoints.length > 10 ? (_chartPoints.length / 6).ceil() : 1;
                if (index % skip != 0 && index != _chartPoints.length - 1) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _chartPoints[index].label,
                    style: const TextStyle(fontSize: 10, color: kDarkGreyColor),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(_chartPoints.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: _chartPoints[index].value,
                width: 12,
                color: kPrimaryColor,
                borderRadius: BorderRadius.circular(6),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxValue,
                  color: kTextfieldBlueColor,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Space.vertical(6),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfilePage()),
                      );
                    },
                    child: const CircleAvatar(
                      radius: 24,
                      backgroundColor: kTextfieldBlueColor,
                      backgroundImage: AssetImage('assets/images/super_admin_avatar.png'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomTextField(
                      topPadding: 10,
                      bottomPadding: 10,
                      readOnly: true,
                      hintText: "Search",
                      prefix: Icon(Icons.search, color: kDarkGreyColor),
                      hintTextColor: kDarkGreyColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  NotificationIconButton(
                    decoration: BoxDecoration(
                      color: kWhiteColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: kGreyColor),
                    ),
                    padding: const EdgeInsets.all(10),
                  ),
                ],
              ),
              Space.vertical(18),
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: 'Total Register',
                      value: _formatSummaryValue(_latestRegisterCount),
                      icon: Icons.supervised_user_circle_outlined,
                      chart: const _MiniAreaChart(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      title: 'Active User',
                      value: _formatSummaryValue(_activeUserCount),
                      icon: Icons.auto_graph_rounded,
                      chart: const _MiniBarGlyph(),
                    ),
                  ),
                ],
              ),
              Space.vertical(18),
              Text('User Growth', style: context.bold.copyWith(fontSize: 24)),
              Space.vertical(12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kWhiteColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: kGreyColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: List.generate(_tabs.length, (index) {
                            final isSelected = selectedTab == index;
                            return Padding(
                              padding: EdgeInsets.only(
                                right: index == _tabs.length - 1 ? 0 : 14,
                              ),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    selectedTab = index;
                                  });
                                  _loadChart();
                                },
                                borderRadius: BorderRadius.circular(5),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: 78,
                                  height: 30,
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? kPrimaryColor
                                        : kWhiteColor,
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color: isSelected
                                          ? kPrimaryColor
                                          : kGreyColor,
                                    ),
                                  ),
                                  child: Text(
                                    _tabs[index],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.normal.copyWith(
                                      fontSize: 12,
                                      color: isSelected
                                          ? kWhiteColor
                                          : kBlackColor,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                    Space.vertical(16),
                    SizedBox(height: 220, child: _buildChartBody()),
                  ],
                ),
              ),
              Space.vertical(18),
              Text('Recent add admin', style: context.bold.copyWith(fontSize: 24)),
              Space.vertical(10),
              _buildRecentAdminsSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Widget chart;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.chart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kGreyColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: kPrimaryColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: kDarkGreyColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          SizedBox(height: 54, child: chart),
        ],
      ),
    );
  }
}

class _MiniAreaChart extends StatelessWidget {
  const _MiniAreaChart();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _MiniAreaPainter());
  }
}

class _MiniAreaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()..color = kPrimaryColor.withValues(alpha: 0.2);
    final strokePaint = Paint()
      ..color = kPrimaryColor
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, size.height * 0.85)
      ..lineTo(size.width * 0.16, size.height * 0.82)
      ..lineTo(size.width * 0.30, size.height * 0.55)
      ..lineTo(size.width * 0.48, size.height * 0.52)
      ..lineTo(size.width * 0.62, size.height * 0.30)
      ..lineTo(size.width * 0.74, size.height * 0.56)
      ..lineTo(size.width * 0.88, size.height * 0.22)
      ..lineTo(size.width, size.height * 0.32);

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MiniBarGlyph extends StatelessWidget {
  const _MiniBarGlyph();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(
        7,
        (index) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == 6 ? 0 : 6),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 18 + (index % 4) * 8.0 + (index * 2),
                decoration: BoxDecoration(
                  color: index.isEven ? kPrimaryColor : kPrimaryColor.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentAdminCard extends StatelessWidget {
  final UserProfile admin;
  final String timeLabel;
  final bool isDeleting;
  final ValueChanged<String>? onMenuSelected;

  const _RecentAdminCard({
    required this.admin,
    required this.timeLabel,
    this.isDeleting = false,
    this.onMenuSelected,
  });

  String _buildInitials(String name) {
    final parts = name
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) return 'A';
    return parts.map((part) => part[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final fullName = '${admin.firstName} ${admin.lastName}'.trim();
    final avatarUrl = admin.applicationMeta?.metaUrl?.trim();
    final status = (admin.isActive ?? '').toUpperCase() == 'Y'
        ? 'Online'
        : 'Offline';
    final item = _RecentAdminItem(
      name: fullName,
      status: status,
      timeLabel: timeLabel,
      initials: _buildInitials(fullName),
      accentColor: kTextfieldBlueColor,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kGreyColor),
      ),
      child: Row(
        children: [
          avatarUrl != null && avatarUrl.isNotEmpty
              ? CircleAvatar(
                  radius: 24,
                  backgroundColor: kTextfieldBlueColor,
                  backgroundImage: avatarUrl.startsWith('assets/')
                      ? AssetImage(avatarUrl)
                      : NetworkImage(avatarUrl),
                  onBackgroundImageError: avatarUrl.startsWith('assets/')
                      ? null
                      : (_, __) {},
                )
              : CircleAvatar(
                  radius: 24,
                  backgroundColor: kTextfieldBlueColor,
                  child: Text(
                    _buildInitials(fullName),
                    style: const TextStyle(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
          Space.horizontal(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName.isEmpty ? admin.email : fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.status}  •  ${item.timeLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: kDarkGreyColor),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            color: kWhiteColor,
            enabled: !isDeleting,
            onSelected: onMenuSelected,
            icon: isDeleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.more_vert, color: kDarkGreyColor),
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'quick',
                child: Text('Quick Actions'),
              ),
              PopupMenuItem<String>(
                value: 'remove',
                child: Text('Remove'),
              ),
              PopupMenuItem<String>(
                value: 'copy',
                child: Text('Copy Link'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartPoint {
  final String label;
  final double value;

  const _ChartPoint({required this.label, required this.value});
}

class _RecentAdminItem {
  final String name;
  final String status;
  final String timeLabel;
  final String initials;
  final Color accentColor;

  const _RecentAdminItem({
    required this.name,
    required this.status,
    required this.timeLabel,
    required this.initials,
    required this.accentColor,
  });
}
