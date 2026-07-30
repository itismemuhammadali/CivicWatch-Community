import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/utils/assets.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/feature/ads/widget/stats_chart_container.dart';
import 'package:flutter/material.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Over view",
                  style: context.bold.copyWith(fontSize: 22, color: kBlackColor),
                ),
                Space.vertical(16),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.unfold_more_rounded,
                        title: "Total view",
                        value: "254612",
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.bar_chart_rounded,
                        title: "Revenue",
                        value: "\$ 2,240.00",
                      ),
                    ),
                  ],
                ),
                Space.vertical(20),
                const StatsChartContainer(),
                Space.vertical(24),
                Text(
                  "Most view by regions",
                  style: context.semiBold.copyWith(fontSize: 18, color: kBlackColor),
                ),
                Space.vertical(16),
                _buildRegionRow("🇺🇸", "United state", "8,288,54"),
                _buildRegionRow("🇬🇧", "United kingdom", "5,143,87"),
                _buildRegionRow("🇵🇱", "Poland", "6,897,29"),
                _buildRegionRow("🇷🇺", "Russia", "9,760,32"),
                _buildRegionRow("🇨🇦", "Canada", "9,984,670", isLast: true),
                Space.vertical(24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegionRow(String flagEmoji, String country, String views, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Text(flagEmoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Text(
                country,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: kBlackColor,
                ),
              ),
              const Spacer(),
              Text(
                views,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: kDarkGreyColor,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(color: kGreyColor.withValues(alpha: 0.4), height: 1),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kGreyColor.withValues(alpha: 0.6)),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F1FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, size: 18, color: kPrimaryColor),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: kDarkGreyColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kBlackColor,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(14),
              ),
              child: CustomPaint(
                size: const Size(90, 45),
                painter: _MiniChartPainter(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          kPrimaryColor.withValues(alpha: 0.8),
          kPrimaryColor.withValues(alpha: 0.95),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    path.moveTo(0, size.height);
    path.cubicTo(
      size.width * 0.3,
      size.height * 0.7,
      size.width * 0.6,
      size.height * 0.2,
      size.width,
      0,
    );
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
