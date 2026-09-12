import 'package:flutter/material.dart';

const Color _textPrimary = Color(0xFF202124);
const Color _textSecondary = Color(0xFF5F6368);

/// Shared layout for the text pages opened from the app drawer.
class InfoPage extends StatelessWidget {
  const InfoPage({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: _textPrimary,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          32 + MediaQuery.paddingOf(context).bottom,
        ),
        children: children,
      ),
    );
  }
}

class InfoSection extends StatelessWidget {
  const InfoSection({
    super.key,
    required this.heading,
    required this.body,
  });

  final String heading;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 15,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

/// Marks a page whose text is a placeholder that still needs legal review.
class DraftNotice extends StatelessWidget {
  const DraftNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF7E0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.edit_note_rounded, color: Color(0xFFB06000)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Draft. This page is a placeholder and must be reviewed by a '
              'legal professional before release.',
              style: TextStyle(
                color: Color(0xFF5F3B00),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
