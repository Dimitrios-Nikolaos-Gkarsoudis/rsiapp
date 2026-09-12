/// Converts an ARGB colour value to the `#rrggbb` string Mapbox styles use.
String mapHexColor(int argb) {
  return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
}
