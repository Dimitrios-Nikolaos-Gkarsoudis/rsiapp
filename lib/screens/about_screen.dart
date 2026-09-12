import 'package:flutter/material.dart';

import '../widgets/info_page.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const InfoPage(
      title: 'About RSI',
      children: [
        InfoSection(
          heading: 'Road Safety Insights',
          body:
              'RSI is a navigation app built to improve road safety. Along '
              'with turn-by-turn directions, it warns you before you reach '
              'road segments with a history of accidents.',
        ),
        InfoSection(
          heading: 'How it works',
          body:
              'RSI matches historical accident locations against your active '
              'route. You are alerted only when a risk zone is on your route '
              'and ahead of you, not simply because an accident happened '
              'nearby.',
        ),
        InfoSection(
          heading: 'Important',
          body:
              'Safety alerts are a driver-assistance and informational '
              'feature. They are not a prediction of future accidents and do '
              'not replace attentive driving, road signs, official traffic '
              'information or emergency services.',
        ),
        InfoSection(
          heading: 'Data sources',
          body:
              'Maps and place search by Mapbox. Routing by OSRM. Accident '
              'data currently covers a test region (Naxos).',
        ),
      ],
    );
  }
}
