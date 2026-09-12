import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../core/text/simple_markdown.dart';

/// Shows a bundled Markdown document, such as the Terms or Privacy Policy.
///
/// The top-level `#` title is not shown because the page's app bar already
/// has it. Text can be selected, so email addresses and links can be copied.
class LegalDocumentView extends StatefulWidget {
  const LegalDocumentView({super.key, required this.assetPath});

  final String assetPath;

  @override
  State<LegalDocumentView> createState() => _LegalDocumentViewState();
}

class _LegalDocumentViewState extends State<LegalDocumentView> {
  static const Color _bodyColor = Color(0xFF3C4043);

  Future<List<DocumentBlock>>? _document;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _document ??= _load(DefaultAssetBundle.of(context));
  }

  Future<List<DocumentBlock>> _load(AssetBundle bundle) async {
    try {
      return parseSimpleMarkdown(await bundle.loadString(widget.assetPath));
    } catch (error) {
      debugPrint('Could not load ${widget.assetPath}: $error');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DocumentBlock>>(
      future: _document,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Text(
              "This document couldn't be loaded. Please try again later.",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
          );
        }

        final blocks = snapshot.data;

        if (blocks == null) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return SelectionArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [for (final block in blocks) _buildBlock(block)],
          ),
        );
      },
    );
  }

  Widget _buildBlock(DocumentBlock block) {
    return switch (block) {
      HeadingBlock(level: 1) => const SizedBox.shrink(),
      HeadingBlock(level: 2, :final text) => Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 6),
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      HeadingBlock(:final text) => Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 4),
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ParagraphBlock(:final text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: _richText(text),
        ),
      BulletBlock(:final text, :final indent) => Padding(
          padding: EdgeInsets.only(left: 4.0 + indent * 18, top: 3, bottom: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '•  ',
                style: TextStyle(color: _bodyColor, fontSize: 15, height: 1.5),
              ),
              Expanded(child: _richText(text)),
            ],
          ),
        ),
    };
  }

  Widget _richText(String text) {
    return Text.rich(
      TextSpan(
        children: [
          for (final (segment, isBold) in parseBoldSegments(text))
            TextSpan(
              text: segment,
              style: isBold
                  ? const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    )
                  : null,
            ),
        ],
      ),
      style: const TextStyle(color: _bodyColor, fontSize: 15, height: 1.5),
    );
  }
}
