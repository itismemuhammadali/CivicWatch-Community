import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:flutter/cupertino.dart';


class SheetHandleBar extends StatelessWidget {
  const SheetHandleBar({super.key, this.topPadding = 9});
  final double topPadding;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: EdgeInsets.only(top: topPadding),
        key: const Key('scroller_feild'),
        width: 92,
        height: 5,
        decoration: BoxDecoration(
          color: kLightGreyColor,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}