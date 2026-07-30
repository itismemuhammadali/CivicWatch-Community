import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:flutter/material.dart';

class RevenueCard extends StatelessWidget {
  final String amount;
  final int year;
  final ValueChanged<int>? onYearChanged;

  const RevenueCard({
    super.key,
    this.amount = "\$5,44,370",
    this.year = 2025,
    this.onYearChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bars = [
      0.5,
      0.35,
      0.8,
      0.45,
      0.6,
      0.75,
      0.2,
      0.55,
      0.4,
      0.85,
      0.6,
      0.7,
      0.2,
      0.55,
      0.4,
      0.85,
    ];
    return Container(
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kGreyColor),
        boxShadow: [
          BoxShadow(
            color: kGreyColor.withValues(alpha:0.04),
            blurRadius: 6,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha:0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.show_chart, color: kPrimaryColor),
              ),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Total\nRevenue",
                    style: context.semiBold.copyWith(fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    amount,
                    style: context.bold.copyWith(
                      fontSize: 26,
                      color: kBlackColor,
                    ),
                  ),
                ],
              ),
              Spacer(),
              // right side: bar mini chart + year dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kWhiteColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<int>(
                  value: year,
                  dropdownColor: kWhiteColor,
                  underline: const SizedBox(),
                  items: [2025, 2024, 2023].map((y) {
                    return DropdownMenuItem(
                      value: y,
                      child: Text(
                        y.toString(),
                        style: TextStyle(color: kBlackColor),
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null && onYearChanged != null) onYearChanged!(v);
                  },
                ),
              ),
            ],
          ),
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: bars.map((b) {
                  final barHeight = 50.0 * b + 6;
                  return Container(
                    width: 12,
                    height: barHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          kPrimaryColor.withValues(alpha:0.95),
                          kPrimaryColor.withValues(alpha:0.6),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
