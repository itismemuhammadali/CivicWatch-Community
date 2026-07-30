import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/feature/ads/widget/schedule_ad_container.dart';
import 'package:flutter/material.dart';

class ScheduleAdView extends StatelessWidget {
  const ScheduleAdView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Column(
        children: [
          ScheduleAdContainer(),
          Space.vertical(10),
          ScheduleAdContainer(),
        ],
      ),
    );
  }
}
