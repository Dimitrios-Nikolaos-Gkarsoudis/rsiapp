/// Minimal Markdown support for documents bundled with the app:
/// `#`, `##` and `###` headings, paragraphs, `- ` bullet lists (indented lines
/// continue a bullet) and `**bold**` text.
sealed class DocumentBlock {
  const DocumentBlock();
}

class HeadingBlock extends DocumentBlock {
  const HeadingBlock(this.level, this.text);

  /// 1 to 3, from `#` to `###`.
  final int level;
  final String text;
}

class ParagraphBlock extends DocumentBlock {
  const ParagraphBlock(this.text);

  final String text;
}

class BulletBlock extends DocumentBlock {
  const BulletBlock(this.text, {this.indent = 0});

  final String text;

  /// 0 for a top-level bullet, 1 for a nested bullet.
  final int indent;
}

final RegExp _headingPattern = RegExp(r'^(#{1,3})\s+(.*)$');
final RegExp _bulletPattern = RegExp(r'^(\s*)[-*]\s+(.*)$');

List<DocumentBlock> parseSimpleMarkdown(String source) {
  final blocks = <DocumentBlock>[];
  final paragraph = <String>[];
  String? bulletText;
  var bulletIndent = 0;

  void flush() {
    final text = bulletText;
    if (text != null) {
      blocks.add(BulletBlock(text, indent: bulletIndent));
      bulletText = null;
    }
    if (paragraph.isNotEmpty) {
      blocks.add(ParagraphBlock(paragraph.join(' ')));
      paragraph.clear();
    }
  }

  for (final rawLine in source.split('\n')) {
    final line = rawLine.replaceAll('\r', '').trimRight();
    final trimmed = line.trimLeft();

    if (trimmed.isEmpty) {
      flush();
      continue;
    }

    final heading = _headingPattern.firstMatch(line);
    if (heading != null) {
      flush();
      blocks.add(HeadingBlock(heading.group(1)!.length, heading.group(2)!.trim()));
      continue;
    }

    final bullet = _bulletPattern.firstMatch(line);
    if (bullet != null) {
      flush();
      bulletText = bullet.group(2)!.trim();
      bulletIndent = bullet.group(1)!.length >= 2 ? 1 : 0;
      continue;
    }

    final currentBullet = bulletText;
    if (currentBullet != null && line.startsWith(' ')) {
      bulletText = '$currentBullet $trimmed';
      continue;
    }

    if (currentBullet != null) {
      flush();
    }
    paragraph.add(trimmed);
  }

  flush();
  return List.unmodifiable(blocks);
}

/// Splits [text] on `**` markers into (text, isBold) segments. Text with
/// unbalanced markers is returned as-is.
List<(String, bool)> parseBoldSegments(String text) {
  final parts = text.split('**');

  if (parts.length.isEven) {
    return [(text, false)];
  }

  return [
    for (var index = 0; index < parts.length; index++)
      if (parts[index].isNotEmpty) (parts[index], index.isOdd),
  ];
}
