import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/feature/ads/widget/active_ad_container.dart';
import 'package:flutter/material.dart';

class ActiveAdView extends StatelessWidget {
  const ActiveAdView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Column(
        children: [
          ActiveAdContainer(),
          Space.vertical(10),
          ActiveAdContainer(),
        ],
      ),
    );
  }
}
