import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/network/models/user_profile.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/feature/adAdmin/widget/admin_container_widget.dart';
import 'package:flutter/material.dart';

class ViewAllAdminPage extends StatelessWidget {
  final String title;
  final List<UserProfile> admins;
  final bool showOnlineStatus;

  const ViewAllAdminPage({
    super.key,
    required this.title,
    required this.admins,
    this.showOnlineStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhiteColor,
      appBar: AppBar(backgroundColor: kWhiteColor, title: Text("")),
      body: Padding(
        padding: const EdgeInsets.only(top: 10, left: 16.0, right: 16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: context.semiBold.copyWith(fontSize: 20)),
                  Text(
                    "Total ${admins.length}",
                    style: context.normal.copyWith(color: kDarkGreyColor),
                  ),
                ],
              ),
              Space.vertical(16),
              if (showOnlineStatus) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text("Online", style: context.normal.copyWith(fontSize: 20)),
                    Space.horizontal(4),
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: kWhiteColor, width: 2),
                      ),
                    ),
                  ],
                ),
                Space.vertical(16),
              ],
              if (admins.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      "No admins found",
                      style: context.normal.copyWith(color: kDarkGreyColor),
                    ),
                  ),
                )
              else
                ...List.generate(admins.length, (index) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: index == admins.length - 1 ? 0 : 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AdminContainerWidget(
                        admin: admins[index],
                        showOnlineStatus: showOnlineStatus,
                        width: double.infinity,
                      ),
                    ),
                  );
                }),
              Space.vertical(20),
            ],
          ),
        ),
      ),
    );
  }
}
