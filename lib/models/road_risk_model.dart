import 'road_segment_model.dart';

/// Risk bands for a 0–100 risk score, each with its map colour.
enum RiskLevel {
  low('low', 'Low risk', 0, 0xFF1E8E3E),
  moderate('moderate', 'Moderate risk', 25, 0xFFF9AB00),
  high('high', 'High risk', 50, 0xFFE8710A),
  veryHigh('very_high', 'Very high risk', 75, 0xFFC5221F);

  const RiskLevel(this.code, this.label, this.minScore, this.colorValue);

  final String code;
  final String label;

  /// Lowest score in this band.
  final int minScore;

  /// ARGB colour for the road line and badges.
  final int colorValue;

  static RiskLevel forScore(int score) {
    if (score >= veryHigh.minScore) return veryHigh;
    if (score >= high.minScore) return high;
    if (score >= moderate.minScore) return moderate;
    return low;
  }
}

/// How risky one road segment is, and the accident data behind it.
class RiskAssessment {
  const RiskAssessment({
    required this.segment,
    required this.score,
    required this.accidentCount,
    required this.fatalAccidents,
    required this.seriousAccidents,
    required this.injuries,
    required this.fatalities,
    this.firstAccidentAt,
    this.lastAccidentAt,
  });

  final RoadSegment segment;

  /// Heuristic risk score from 0 (lowest) to 100 (highest).
  final int score;

  final int accidentCount;
  final int fatalAccidents;
  final int seriousAccidents;
  final int injuries;
  final int fatalities;

  /// Period covered by the dated accidents on this segment.
  final DateTime? firstAccidentAt;
  final DateTime? lastAccidentAt;

  RiskLevel get level => RiskLevel.forScore(score);
}
