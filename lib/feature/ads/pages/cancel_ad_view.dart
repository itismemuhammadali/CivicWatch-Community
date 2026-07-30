import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/feature/ads/widget/cancel_ad_container.dart';
import 'package:flutter/material.dart';

class CancelAdView extends StatelessWidget {
  const CancelAdView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Column(
        children: [
          CancelAdContainer(),
          Space.vertical(10),
          CancelAdContainer(),
        ],
      ),
    );
  }
}
