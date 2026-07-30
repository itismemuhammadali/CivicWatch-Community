import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:flutter/material.dart';


import 'space.dart';

class AppBottomSheet extends StatefulWidget {
  const AppBottomSheet({
    super.key,
    this.isGreyHandleShow = true,
    required this.body,
    this.borderRadius = 32,
    this.backgroundColor = kWhiteColor,
    this.canApplyExplicitStyling = true,
    this.scrollController,
    this.enableScrollView = true,
  });
  final bool isGreyHandleShow;
  final Widget body;
  final Color backgroundColor;
  final double borderRadius;
  final bool canApplyExplicitStyling;
  final bool enableScrollView;
  final ScrollController? scrollController;
  static Future<T?> show<T>(
    BuildContext context, {
    bool showSheetHandler = true,
    bool isTransparent = false,
    bool isDismissible = true,
    bool enableDrag = true,
    bool enableScrollView = true,
    required Widget body,
    Color backgroundColor = kWhiteColor,
    double borderRadius = 12,
    ScrollController? scrollController,
  }) async {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(borderRadius),
          topRight: Radius.circular(borderRadius),
        ),
      ),
      scrollControlDisabledMaxHeightRatio: 0.85,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: AppBottomSheet(
          body: body,
          isGreyHandleShow: showSheetHandler,
          backgroundColor: backgroundColor,
          borderRadius: borderRadius,
          scrollController: scrollController,
          enableScrollView: enableScrollView,
        ),
      ),
    );
  }

  static void hide(BuildContext context) {
    Navigator.pop(context);
  }

  @override
  State<AppBottomSheet> createState() => _AppBottomSheetState();
}

class _AppBottomSheetState extends State<AppBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.zero,
      decoration: widget.canApplyExplicitStyling
          ? BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(widget.borderRadius),
                topRight: Radius.circular(widget.borderRadius),
              ),
            )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isGreyHandleShow) ...[
            // SheetHandleBar(),
            const Space.vertical(24),
          ],
          if (widget.enableScrollView)
            Flexible(
              child: SingleChildScrollView(
                controller: widget.scrollController,
                child: widget.body,
              ),
            )
          else
            Expanded(child: widget.body),
        ],
      ),
    );
  }
}

class SheetHandleBar {
  const SheetHandleBar();
}
