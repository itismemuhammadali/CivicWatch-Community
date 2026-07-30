import 'package:cctv_app/core/extensions/context.dart';
import 'package:flutter/material.dart';

class ViewAllWidget extends StatelessWidget {
  final String text;
  final VoidCallback onClickViewAll;
  const ViewAllWidget({
    super.key,
    required this.text,
    required this.onClickViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(text, style: context.semiBold.copyWith(fontSize: 20)),
        TextButton(
          onPressed: onClickViewAll,
          child: Text("View all", style: context.normal),
        ),
      ],
    );
  }
}
