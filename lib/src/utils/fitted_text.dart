import 'dart:math';
import 'package:flutter/material.dart';
import 'package:paginated_text/src/extensions/line_metrics_extension.dart';

class FittedText {
  final double height;
  final List<String> lines;

  const FittedText({
    required this.height,
    required this.lines,
  });

  static FittedText fit({
    required String text,
    required double width,
    required TextScaler textScaler,
    required TextDirection textDirection,
    required TextStyle style,
    required int maxLines,
  }) {
    assert(maxLines > 0, 'maxLines = $maxLines; must be > 0');

    final textSpan = TextSpan(
      text: text,
      style: style,
    );

    final strutStyle = StrutStyle.fromTextStyle(style);

    final textPainter = TextPainter(
      text: textSpan,
      textScaler: textScaler,
      textDirection: textDirection,
      strutStyle: strutStyle,
      maxLines: maxLines,
    )..layout(
        minWidth: width,
        maxWidth: width,
      );

    final List<LineMetrics> lineMetrics = textPainter.computeLineMetrics();
    final List<String> lines = lineMetrics.map((line) {
      final start = textPainter.getPositionForOffset(line.leftBaseline).offset;
      final end =
          1 + textPainter.getPositionForOffset(line.rightBaseline).offset;
      final lineText = text.substring(start, min(end, text.length));
      return lineText;
    }).toList();

    return FittedText(
      height: lineMetrics.last.bottom,
      lines: lines,
    );
  }
}
