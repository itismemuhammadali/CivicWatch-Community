import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/feature/ads/widget/pending_ad_container.dart';
import 'package:flutter/material.dart';

class PendingAdView extends StatelessWidget {
  const PendingAdView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Column(
        children: [
          PendingAdContainer(),
          Space.vertical(10),
          PendingAdContainer(),
        ],
      ),
    );
  }
}
