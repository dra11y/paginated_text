double getCapFontSize({
  required double textFontSize,
  required double lineHeight,
  required int capLines,
  required double textLetterHeightRatio,
  required double capLetterHeightRatio,
}) {
  final wantedCapLetterHeight = ((textFontSize * lineHeight) * (capLines - 1) +
          (textFontSize * textLetterHeightRatio))
      .ceil();
  return (wantedCapLetterHeight / capLetterHeightRatio).ceilToDouble();
}
