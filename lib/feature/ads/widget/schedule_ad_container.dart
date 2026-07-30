import 'package:cctv_app/core/components/primary_button.dart';
import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/utils/assets.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/feature/ads/pages/stats_page.dart';
import 'package:flutter/material.dart';

class ScheduleAdContainer extends StatelessWidget {
  const ScheduleAdContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kGreyColor),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              Assets.pngHighlight2Image,
              width: 104,
              height: 132,
              fit: BoxFit.cover,
            ),
          ),
          Space.horizontal(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Arrivals Just Dropped!',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Space.vertical(10),
                _buildInfoRow('Create Date', 'May 1, 2025'),
                Space.vertical(6),
                _buildInfoRow('Start Date', 'May 1, 2025'),
                Space.vertical(12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    PrimaryButton(
                      text: 'Pending',
                      height: 32,
                      isMainAxisSizeMin: true,
                      buttonColor: kPrimaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      onPressed: () {},
                    ),
                    PrimaryButton(
                      text: 'End',
                      height: 32,
                      isMainAxisSizeMin: true,
                      showBorder: true,
                      buttonColor: kWhiteColor,
                      borderColor: kGreyColor,
                      textColor: kBlackColor,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      onPressed: () {
                        showEndAdDialog(context);
                      },
                    ),
                    PrimaryButton(
                      text: 'Stats',
                      height: 32,
                      isMainAxisSizeMin: true,
                      showBorder: true,
                      buttonColor: kWhiteColor,
                      borderColor: kGreyColor,
                      textColor: kBlackColor,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => StatsPage()),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, color: kDarkGreyColor),
          ),
        ),
      ],
    );
  }

  void showEndAdDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: kWhiteColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Are you sure?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Space.vertical(10),
              const Text(
                'Stopping this ad will immediately pause its visibility on the app. Users will no longer see it until you reactivate.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
              ),
              Space.vertical(10),
              const Text(
                'Do you still want to proceed?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
              ),
              Space.vertical(20),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: kWhiteColor,
                        border: Border.all(color: kRedColor),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'No',
                        style: context.normal.copyWith(color: kBlackColor),
                      ),
                    ),
                  ),
                  Space.horizontal(10),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: kRedColor,
                        border: Border.all(color: kRedColor),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Yes',
                        style: context.normal.copyWith(color: kWhiteColor),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
