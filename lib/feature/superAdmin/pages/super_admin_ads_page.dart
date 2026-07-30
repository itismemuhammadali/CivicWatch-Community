import 'package:cctv_app/core/components/current_user_avatar.dart';
import 'package:cctv_app/core/components/custom_textfield.dart';
import 'package:cctv_app/core/components/notification_icon_button.dart';
import 'package:cctv_app/core/components/primary_button.dart';
import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/feature/ads/pages/create_ad_page.dart';
import 'package:cctv_app/feature/ads/pages/stats_page.dart';
import 'package:cctv_app/feature/profile/pages/profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SuperAdminAdsPage extends StatefulWidget {
  const SuperAdminAdsPage({super.key});

  @override
  State<SuperAdminAdsPage> createState() => _SuperAdminAdsPageState();
}

class _SuperAdminAdsPageState extends State<SuperAdminAdsPage> {
  int _selectedIndex = 0;
  final _tabs = ['Active Ads', 'Pending Ads', 'Scheduled Ads', 'Cancel'];
  final _statusKeys = ['active', 'pending', 'scheduled', 'cancel'];

  @override
  Widget build(BuildContext context) {
    final currentStatusKey = _statusKeys[_selectedIndex];

    return Scaffold(
      backgroundColor: kWhiteColor,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Space.vertical(10),
              // Header
              Row(
                children: [
                  CurrentUserAvatar(
                    radius: 24,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfilePage()),
                      );
                    },
                  ),
                  Space.horizontal(10),
                  Expanded(
                    child: CustomTextField(
                      topPadding: 10,
                      bottomPadding: 10,
                      hintText: "Search",
                      prefix: const Icon(Icons.search, color: kDarkGreyColor),
                      hintTextColor: kDarkGreyColor,
                    ),
                  ),
                  Space.horizontal(10),
                  NotificationIconButton(
                    decoration: BoxDecoration(
                      color: kWhiteColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: kGreyColor),
                    ),
                    padding: const EdgeInsets.all(10),
                  ),
                ],
              ),
              Space.vertical(20),
              Align(
                alignment: Alignment.centerRight,
                child: PrimaryButton(
                  text: "Create new ads",
                  height: 36,
                  isMainAxisSizeMin: true,
                  postfixIcon: const Icon(Icons.add, color: kWhiteColor, size: 20),
                  onPressed: () async {
                    final created = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (context) => const CreateAdPage()),
                    );
                    if (created == true) {
                      setState(() {});
                    }
                  },
                ),
              ),
              Space.vertical(20),
              Text(
                _tabs[_selectedIndex], 
                style: context.semiBold.copyWith(fontSize: 22, color: kBlackColor),
              ),
              Space.vertical(12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_tabs.length, (index) {
                    final isSelected = _selectedIndex == index;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 20),
                        padding: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: isSelected ? kPrimaryColor : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          _tabs[index],
                          style: context.medium.copyWith(
                            fontSize: 14,
                            color: isSelected ? kBlackColor : kDarkGreyColor,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Space.vertical(16),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance.collection('ads').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data?.docs ?? [];
                    final filteredDocs = docs.where((doc) {
                      final data = doc.data();
                      final st = (data['status'] ?? 'active').toString().toLowerCase();
                      if (currentStatusKey == 'active') {
                        return st == 'active' || st == 'draft';
                      }
                      return st == currentStatusKey;
                    }).toList();

                    if (filteredDocs.isEmpty) {
                      return Center(
                        child: Text(
                          'No ads found for ${_tabs[_selectedIndex]}', 
                          style: context.normal.copyWith(color: kDarkGreyColor),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: filteredDocs.length,
                      separatorBuilder: (_, __) => Space.vertical(12),
                      itemBuilder: (context, index) {
                        final data = filteredDocs[index].data();
                        final docId = filteredDocs[index].id;
                        return _buildDynamicAdCard(docId, data);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicAdCard(String docId, Map<String, dynamic> data) {
    final title = data['title']?.toString() ?? 'Untitled Ad';
    final startDate = data['startAt']?.toString() ?? 'Today';
    final runDays = '${data['runDays'] ?? 30} days';
    final coverUrl = data['coverImageUrl']?.toString() ?? '';
    final status = (data['status'] ?? 'active').toString();

    return Container(
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kGreyColor.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 100,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFFACC46),
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: coverUrl.isNotEmpty
                ? Image.network(
                    coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.image_not_supported, color: kDarkGreyColor),
                    ),
                  )
                : const Center(
                    child: Icon(Icons.campaign, size: 36, color: kWhiteColor),
                  ),
          ),
          Space.horizontal(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.semiBold.copyWith(fontSize: 14, color: kBlackColor),
                ),
                Space.vertical(12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Start Date", style: context.semiBold.copyWith(fontSize: 12, color: kBlackColor)),
                    Text(startDate, style: context.normal.copyWith(fontSize: 11, color: kDarkGreyColor)),
                  ],
                ),
                Space.vertical(8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Run Days", style: context.semiBold.copyWith(fontSize: 12, color: kBlackColor)),
                    Text(runDays, style: context.normal.copyWith(fontSize: 11, color: kDarkGreyColor)),
                  ],
                ),
                Space.vertical(12),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: GestureDetector(
                        onTap: () async {
                          final newStatus = status == 'active' ? 'cancel' : 'active';
                          await FirebaseFirestore.instance.collection('ads').doc(docId).update({'status': newStatus});
                        },
                        child: Container(
                          height: 30,
                          decoration: BoxDecoration(
                            color: status == 'active' ? const Color(0xFFE9253F) : kDarkGreyColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: Text(status == 'active' ? "End" : "Activate", style: context.semiBold.copyWith(fontSize: 12, color: kWhiteColor)),
                        ),
                      ),
                    ),
                    Space.horizontal(8),
                    Expanded(
                      flex: 1,
                      child: GestureDetector(
                        onTap: () async {
                          final newStatus = status == 'paused' ? 'active' : 'paused';
                          await FirebaseFirestore.instance.collection('ads').doc(docId).update({'status': newStatus});
                        },
                        child: Container(
                          height: 30,
                          decoration: BoxDecoration(
                            color: kWhiteColor,
                            border: Border.all(color: kGreyColor),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: Text(status == 'paused' ? "Resume" : "Pause", style: context.semiBold.copyWith(fontSize: 12, color: kBlackColor)),
                        ),
                      ),
                    ),
                    Space.horizontal(8),
                    Expanded(
                      flex: 1,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const StatsPage()),
                          );
                        },
                        child: Container(
                          height: 30,
                          decoration: BoxDecoration(
                            color: kWhiteColor,
                            border: Border.all(color: kGreyColor),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: Text("Stats", style: context.semiBold.copyWith(fontSize: 12, color: kBlackColor)),
                        ),
                      ),
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
}
