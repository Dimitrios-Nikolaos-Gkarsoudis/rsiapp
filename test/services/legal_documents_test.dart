import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rsi/core/text/simple_markdown.dart';
import 'package:rsi/screens/legal/privacy_policy_screen.dart';
import 'package:rsi/screens/legal/terms_screen.dart';

Future<List<String>> _sectionHeadings(String assetPath) async {
  final blocks = parseSimpleMarkdown(await rootBundle.loadString(assetPath));
  return [
    for (final block in blocks)
      if (block is HeadingBlock && block.level == 2) block.text,
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('legal documents have numbered sections in order', () async {
    for (final (assetPath, expectedSections) in [
      (TermsScreen.assetPath, 18),
      (PrivacyPolicyScreen.assetPath, 13),
    ]) {
      final headings = await _sectionHeadings(assetPath);

      expect(headings, hasLength(expectedSections), reason: assetPath);
      for (var index = 0; index < headings.length; index++) {
        expect(
          headings[index],
          startsWith('${index + 1}. '),
          reason: '$assetPath section ${index + 1}',
        );
      }
    }
  });
}
