import 'package:flutter/material.dart';

import '../../widgets/info_page.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const InfoPage(
      title: 'Privacy Policy',
      children: [
        DraftNotice(),
        InfoSection(
          heading: 'Location',
          body:
              'RSI uses your device location to show your position, calculate '
              'routes and detect hazards ahead of you. During navigation, '
              'location may also be used while the app is in the background.',
        ),
        InfoSection(
          heading: 'Place search',
          body:
              'Text you type into search is sent to Mapbox to find matching '
              'places.',
        ),
        InfoSection(
          heading: 'Routing',
          body:
              'Your start and destination coordinates are sent to a routing '
              'service (currently OSRM) to calculate your route.',
        ),
        InfoSection(
          heading: 'Accident data',
          body:
              'Historical accident data is bundled with the app and processed '
              'on your device.',
        ),
        InfoSection(
          heading: 'Data retention and your rights',
          body: '[To be provided.]',
        ),
        InfoSection(
          heading: 'Contact',
          body: '[To be provided.]',
        ),
      ],
    );
  }
}
