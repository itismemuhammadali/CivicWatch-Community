import 'package:flutter/material.dart';
import 'package:cctv_app/core/utils/color_constants.dart';

class StatsChartContainer extends StatelessWidget {
  const StatsChartContainer({super.key});

  @override
  Widget build(BuildContext context) {
    final List<double> barRatios = [0.55, 0.30, 0.70, 0.50, 0.65, 0.85, 0.60];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhiteColor,
        border: Border.all(color: kGreyColor.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "854",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_upward, size: 16, color: Colors.black),
              const SizedBox(width: 2),
              const Text(
                "25 upward",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final ratio = barRatios[index];
              return Container(
                width: 14,
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: 14,
                    height: 140 * ratio,
                    decoration: BoxDecoration(
                      color: kPrimaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          const Text(
            "Summer Sale – 30% Off",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Promoting seasonal discounts on summer wear.\nAimed to increase conversions on trending items.",
            style: TextStyle(
              fontSize: 13,
              color: kDarkGreyColor,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
