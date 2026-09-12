import 'package:flutter/material.dart';

import '../config/app_routes.dart';

class _DrawerDestination {
  const _DrawerDestination({
    required this.icon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final String label;
  final String route;
}

/// Side menu opened from the burger button in the map search bar.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  static const Color _mapsBlue = Color(0xFF1A73E8);
  static const Color _textPrimary = Color(0xFF202124);
  static const Color _textSecondary = Color(0xFF5F6368);

  static const List<_DrawerDestination> _destinations = [
    _DrawerDestination(
      icon: Icons.info_outline_rounded,
      label: 'About RSI',
      route: AppRoutes.about,
    ),
    _DrawerDestination(
      icon: Icons.description_outlined,
      label: 'Terms & Conditions',
      route: AppRoutes.terms,
    ),
    _DrawerDestination(
      icon: Icons.privacy_tip_outlined,
      label: 'Privacy Policy',
      route: AppRoutes.privacy,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const _Header(),
            const Divider(height: 1),
            const SizedBox(height: 8),
            for (final destination in _destinations)
              _DestinationTile(destination: destination),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F0FE),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.shield_rounded,
              color: AppDrawer._mapsBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RSI',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppDrawer._textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Road Safety Insights',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppDrawer._textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DestinationTile extends StatelessWidget {
  const _DestinationTile({required this.destination});

  final _DrawerDestination destination;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Icon(destination.icon, color: AppDrawer._textSecondary),
      title: Text(
        destination.label,
        style: const TextStyle(
          color: AppDrawer._textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: () {
        final navigator = Navigator.of(context);
        navigator.pop();
        navigator.pushNamed(destination.route);
      },
    );
  }
}
