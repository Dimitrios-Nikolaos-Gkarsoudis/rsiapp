import 'package:flutter/material.dart';

import '../../widgets/info_page.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const InfoPage(
      title: 'Terms & Conditions',
      children: [
        DraftNotice(),
        InfoSection(
          heading: 'About these terms',
          body:
              'These terms govern your use of the RSI app. '
              '[Full text to be provided.]',
        ),
        InfoSection(
          heading: 'Safety alerts are informational',
          body:
              'RSI is a driver-assistance tool. Alerts are based on historical '
              'accident data and are not a guaranteed prediction of future '
              'accidents. They do not replace attentive driving, road signs, '
              'official traffic information or emergency services.',
        ),
        InfoSection(
          heading: 'Routes and navigation',
          body:
              'Routes are calculated by third-party services and may be '
              'inaccurate or out of date. Always follow road signs and local '
              'traffic laws.',
        ),
        InfoSection(
          heading: 'Limitation of liability',
          body: '[To be provided.]',
        ),
        InfoSection(
          heading: 'Changes and contact',
          body: '[To be provided.]',
        ),
      ],
    );
  }
}
