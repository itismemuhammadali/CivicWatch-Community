import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:flutter/material.dart';

class CustomHorizontalListViewWidget extends StatelessWidget {
  final List<String> items;
  final int selectedItem;
  final ValueChanged<int> onTap;
  const CustomHorizontalListViewWidget({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          children: List.generate(items.length, (index) {
            final isSelected = index == selectedItem;

            return GestureDetector(
              onTap: () => onTap(index),
              child: Container(
                height: 30,
                constraints: const BoxConstraints(minWidth: 78),
                margin: EdgeInsets.only(
                  right: index == items.length - 1 ? 0 : 14,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? kPrimaryColor : kWhiteColor,
                  border: Border.all(
                    color: isSelected ? kPrimaryColor : kGreyColor,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  items[index],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.normal.copyWith(
                    color: isSelected ? kWhiteColor : kBlackColor,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
