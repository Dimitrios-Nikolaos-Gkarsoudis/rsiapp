import 'package:flutter/material.dart';

import '../screens/about_screen.dart';
import '../screens/legal/privacy_policy_screen.dart';
import '../screens/legal/terms_screen.dart';

/// Named routes for the pages opened from the app drawer.
class AppRoutes {
  const AppRoutes._();

  static const String about = '/about';
  static const String terms = '/terms';
  static const String privacy = '/privacy';

  static final Map<String, WidgetBuilder> routes = {
    about: (_) => const AboutScreen(),
    terms: (_) => const TermsScreen(),
    privacy: (_) => const PrivacyPolicyScreen(),
  };
}
