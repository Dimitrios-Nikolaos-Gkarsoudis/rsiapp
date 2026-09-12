import 'package:flutter/material.dart';

import '../../widgets/info_page.dart';
import '../../widgets/legal/legal_document_view.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const String assetPath = 'assets/legal/privacy_policy.md';

  @override
  Widget build(BuildContext context) {
    return const InfoPage(
      title: 'Privacy Policy',
      children: [LegalDocumentView(assetPath: assetPath)],
    );
  }
}
