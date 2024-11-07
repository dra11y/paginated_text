import 'package:flutter/painting.dart';

extension StringExt on String {
  String get withNewline => contains('\n') ? this : '$this\n';
}

extension ListEqualityExt<T> on List<T> {
  bool equals(List<T> other) =>
      length == other.length && indexed.every((e) => other[e.$1] == e.$2);
}

extension ListLineMetricsTextExt on List<LineMetrics> {
  List<String> getLineTexts(TextPainter painter, String text) =>
      map((line) => line.lineText(painter, text)).toList();
}

extension LineMetricsTextExt on LineMetrics {
  String lineText(TextPainter painter, String text) {
    // Lots of inconsistencies in `TextPainter` and `LineMetrics`.
    // One bug in `TextPainter` causes the last line to be duplicated, but it has width 0.
    // Most lines whose `width` == 0 are newlines, but we check `hardBreak` to be sure.
    // Without this early return, the last line of text is duplicated.
    // Besides, we need not compute the boundary if `width` == 0.
    if (width == 0) {
      return hardBreak ? '\n' : '';
    }

    final linePosition =
        painter.getPositionForOffset(Offset(left + width / 2, baseline));
    final boundary = painter.getLineBoundary(linePosition);

    // from getLineBoundary: The newline (if any) is not returned as part of the range.
    // but calls Paragraph.getLineBoundary: The newline (if any) is returned as part of the range.
    // Which is it?
    // Through experimentation, the first is true.
    final start = boundary.start;
    final end = (hardBreak && boundary.end < text.length)
        ? boundary.end + 1
        : boundary.end;
    final lineText = text.substring(start, end);
    return lineText;
  }
}

extension DebugListStringExt on List {
  String debugString() {
    final buffer = StringBuffer('\n');
    for (var i = 0; i < length; i++) {
      buffer.writeln('[$i] ${this[i]}');
    }
    return buffer.toString();
  }
}
