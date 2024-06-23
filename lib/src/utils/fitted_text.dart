import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:paginated_text/src/extensions/line_metrics_extension.dart';

class FittedText {
  final double height;
  final List<String> lines;
  final bool didExceedMaxLines;

  const FittedText({
    required this.height,
    required this.lines,
    required this.didExceedMaxLines,
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
    final List<String> lines = lineMetrics.mapIndexed((index, line) {
      final lineStart = textPainter.getPositionForOffset(line.leftBaseline);
      final boundary = textPainter.getLineBoundary(lineStart);
      final lineText =
          text.substring(boundary.start, min(boundary.end, text.length));
      // debugPrint('line $index: |$lineText|');
      return lineText;
    }).toList();

    return FittedText(
      height: lineMetrics.last.bottom,
      lines: lines,
      didExceedMaxLines: textPainter.didExceedMaxLines,
    );
  }
}
