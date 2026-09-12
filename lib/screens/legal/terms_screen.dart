import 'package:flutter/material.dart';

import '../../widgets/info_page.dart';
import '../../widgets/legal/legal_document_view.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const String assetPath = 'assets/legal/terms_and_conditions.md';

  @override
  Widget build(BuildContext context) {
    return const InfoPage(
      title: 'Terms & Conditions',
      children: [LegalDocumentView(assetPath: assetPath)],
    );
  }
}
