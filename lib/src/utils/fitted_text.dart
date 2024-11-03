import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:paginated_text/src/extensions/line_metrics_extension.dart';

class FittedText {
  final double height;
  final List<String> lines;
  final String text;
  final bool didExceedMaxLines;

  const FittedText({
    required this.height,
    required this.lines,
    required this.text,
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

    // Skip first empty line(s)
    final textLines =
        text.split('\n').skipWhile((line) => line.trim().isEmpty).toList();

    // TODO: Test this! Remove final blank lines
    for (int i = textLines.length - 1; i > 0; i--) {
      if (textLines[i].trim().isNotEmpty) {
        break;
      }
      textLines.removeAt(i);
    }

    final trimmedText = textLines.join('\n');

    final textSpan = TextSpan(
      text: trimmedText,
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

    List<LineMetrics> lineMetrics = textPainter.computeLineMetrics();
    if (textPainter.didExceedMaxLines) {
      lineMetrics = lineMetrics.sublist(0, maxLines);
    }

    final List<String> lines = lineMetrics.mapIndexed((index, line) {
      final lineStart = textPainter.getPositionForOffset(line.leftBaseline);
      final boundary = textPainter.getLineBoundary(lineStart);

      /// from getLineBoundary: The newline (if any) is not returned as part of the range.
      /// but calls Paragraph.getLineBoundary: The newline (if any) is returned as part of the range.
      /// Which is it?
      /// Through experimentation, the first is true.
      final end = line.hardBreak ? boundary.end + 1 : boundary.end;
      final lineText =
          trimmedText.substring(boundary.start, min(end, trimmedText.length));
      return lineText;
    }).toList();

    // debugPrint('lines.last: ${lines.last}');

    return FittedText(
      height: lineMetrics.lastOrNull?.bottom ?? 0,
      lines: lines,
      text: lines.join(),
      didExceedMaxLines: textPainter.didExceedMaxLines,
    );
  }

  @override
  String toString() => [
        '$runtimeType(',
        '    height: $height,',
        '    lines: $lines,',
        '    didExceedMaxLines: $didExceedMaxLines,',
        ')',
      ].join('\n');
}
