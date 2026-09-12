import 'package:flutter/material.dart';
import '../services/mapbox_service.dart';

class SearchHeaderCard extends StatelessWidget {
  final TextEditingController originController;
  final TextEditingController destController;
  final FocusNode originFocusNode;
  final FocusNode destFocusNode;
  final bool isExpanded;
  final List<MapboxSearchResult> suggestions;
  final Function(String, bool) onSearchChanged;
  final VoidCallback onToggleExpand;
  final Function(MapboxSearchResult) onSelectPlace;

  const SearchHeaderCard({
    super.key,
    required this.originController,
    required this.destController,
    required this.originFocusNode,
    required this.destFocusNode,
    required this.isExpanded,
    required this.suggestions,
    required this.onSearchChanged,
    required this.onToggleExpand,
    required this.onSelectPlace,
  });

  @override
  Widget build(BuildContext context) {
    // Using Theme.of(context) allows us to easily implement light/dark mode later
    final theme = Theme.of(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white12),
            boxShadow: const [
              BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 4))
            ],
          ),
          child: Column(
            children: [
              _buildSearchRow(
                icon: Icons.my_location_rounded,
                iconColor: Colors.blueAccent,
                controller: originController,
                focusNode: originFocusNode,
                hintText: "Αφετηρία (π.χ. Η τοποθεσία μου)...",
                isOrigin: true,
                trailingIcon: IconButton(
                  icon: Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.white60,
                    size: 20,
                  ),
                  onPressed: onToggleExpand,
                ),
              ),
              if (isExpanded) ...[
                const Divider(color: Colors.white12, height: 12),
                _buildSearchRow(
                  icon: Icons.location_on_rounded,
                  iconColor: Colors.redAccent,
                  controller: destController,
                  focusNode: destFocusNode,
                  hintText: "Πού θέλετε να πάτε;",
                  isOrigin: false,
                ),
              ],
            ],
          ),
        ),
        if (suggestions.isNotEmpty) _buildSuggestionsList(theme),
      ],
    );
  }

  Widget _buildSearchRow({
    required IconData icon,
    required Color iconColor,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required bool isOrigin,
    Widget? trailingIcon,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            style: const TextStyle(color: Colors.white, fontSize: 13.5),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.white38),
              border: InputBorder.none,
              isDense: true,
            ),
            onTap: !isExpanded && isOrigin ? onToggleExpand : null,
            onChanged: (val) => onSearchChanged(val, isOrigin),
          ),
        ),
        ?trailingIcon,
      ],
    );
  }

  Widget _buildSuggestionsList(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
        boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 20)],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: suggestions.length,
        separatorBuilder: (context, index) => const Divider(color: Colors.white12, height: 1),
        itemBuilder: (context, index) {
          final item = suggestions[index];
          return ListTile(
            dense: true,
            leading: const Icon(Icons.place_outlined, color: Colors.lightBlueAccent, size: 20),
            title: Text(item.displayName, maxLines: 2, style: const TextStyle(color: Colors.white, fontSize: 13)),
            onTap: () => onSelectPlace(item),
          );
        },
      ),
    );
  }
}