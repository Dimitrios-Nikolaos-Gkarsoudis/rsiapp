import 'package:flutter_test/flutter_test.dart';
import 'package:rsi/map/map_colors.dart';

void main() {
  test('drops alpha and formats as #rrggbb', () {
    expect(mapHexColor(0xFFC5221F), '#c5221f');
  });

  test('keeps leading zeros', () {
    expect(mapHexColor(0xFF0000FF), '#0000ff');
  });
}
