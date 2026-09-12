import 'package:flutter_test/flutter_test.dart';
import 'package:rsi/core/text/simple_markdown.dart';

void main() {
  test('parses headings, paragraphs and bullets in order', () {
    final blocks = parseSimpleMarkdown('''
# Title

## 1. Section
First line of a paragraph
continues here.

- First bullet
  continues on the next line
- Second bullet
  - Nested bullet
After the list.
''');

    expect(blocks, hasLength(7));

    final title = blocks[0] as HeadingBlock;
    expect(title.level, 1);
    expect(title.text, 'Title');

    final section = blocks[1] as HeadingBlock;
    expect(section.level, 2);
    expect(section.text, '1. Section');

    expect(
      (blocks[2] as ParagraphBlock).text,
      'First line of a paragraph continues here.',
    );
    expect(
      (blocks[3] as BulletBlock).text,
      'First bullet continues on the next line',
    );
    expect((blocks[4] as BulletBlock).text, 'Second bullet');

    final nested = blocks[5] as BulletBlock;
    expect(nested.text, 'Nested bullet');
    expect(nested.indent, 1);

    expect((blocks[6] as ParagraphBlock).text, 'After the list.');
  });

  test('treats ### as a level 3 heading and ignores blank lines', () {
    final blocks = parseSimpleMarkdown('\n\n### Location\n\n\nText\n');

    expect(blocks, hasLength(2));
    expect((blocks[0] as HeadingBlock).level, 3);
    expect((blocks[1] as ParagraphBlock).text, 'Text');
  });

  test('splits bold segments', () {
    expect(parseBoldSegments('A **bold** word'), [
      ('A ', false),
      ('bold', true),
      (' word', false),
    ]);
  });

  test('leaves text with unbalanced bold markers unchanged', () {
    expect(parseBoldSegments('A **broken word'), [('A **broken word', false)]);
  });
}
