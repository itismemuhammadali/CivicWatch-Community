import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/core/utils/legal_documents.dart';
import 'package:flutter/material.dart';

class TermsAndPolicies extends StatelessWidget {
  const TermsAndPolicies({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhiteColor,
      appBar: AppBar(backgroundColor: kWhiteColor),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 10, left: 16.0, right: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _LegalDocumentSection(
              eyebrow: 'USER LICENSE',
              title: 'End User License Agreement',
              body: cctvEndUserLicenseAgreementText,
            ),
            _LegalDocumentSection(
              eyebrow: 'PRIVACY POLICY',
              title: 'Privacy Policy',
              body: cctvPrivacyPolicyText,
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _LegalDocumentSection extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String body;

  const _LegalDocumentSection({
    required this.eyebrow,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: context.normal.copyWith(
              color: kDarkGreyColor,
              fontSize: 14,
            ),
          ),
          Space.vertical(10),
          Text(title, style: context.bold.copyWith(fontSize: 18)),
          Space.vertical(10),
          Divider(color: kGreyColor, thickness: 1),
          Space.vertical(10),
          SelectableText(
            body,
            style: context.normal.copyWith(
              color: kDarkGreyColor,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
