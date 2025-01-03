import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

extension TextSpanExt on TextSpan {
  // Helper function to recursively split
  TextSpan _splitSpanAtOffset(int offset) {
    final currentText = text ?? '';
    if (offset <= currentText.length && currentText.isNotEmpty) {
      final leftText = currentText.substring(0, offset);
      final rightText = currentText.substring(offset);
      return copyWith(
        text: leftText,
        children: [],
      ).copyWith(children: [
        copyWith(
          text: rightText,
          children: [],
        )
      ]);
    }

    var remainingOffset = offset - currentText.length;
    final newChildren = <TextSpan>[];
    for (var i = 0; i < (children?.length ?? 0); i++) {
      final child = children![i];
      if (child is! TextSpan) {
        continue;
      }
      final childLength = child.toPlainText().length;
      if (remainingOffset <= childLength) {
        final splitChild = _splitSpanAtOffset(remainingOffset);
        // splitChild is a span with left & right parts as children
        final splitChildren = splitChild.children ?? [];
        final leftSpan = copyWith(text: currentText, children: [
          ...newChildren,
          if (splitChildren.isNotEmpty) splitChildren.first,
        ]);
        final rightSpan = copyWith(
          text: '',
          children: [
            if (splitChildren.length > 1) splitChildren.last,
            ...children?.skip(i + 1) ?? [],
          ],
        );
        return leftSpan.copyWith(children: [rightSpan]);
      }
      remainingOffset -= childLength;
      newChildren.add(child);
    }

    return this;
  }

  List<TextSpan> split(int offset) {
    if (offset < 0) {
      throw ArgumentError.value(offset, 'offset', 'cannot be negative');
    }
    final text = toPlainText(
      includeSemanticsLabels: false,
      includePlaceholders: false,
    );
    if (offset == 0 || offset >= text.length - 1) {
      return [this];
    }

    // Actual split call
    final splitResult = _splitSpanAtOffset(offset);
    return [
      splitResult.children!.first as TextSpan,
      splitResult.children!.last as TextSpan
    ];
  }

  TextSpan copyWith({
    String? text,
    List<InlineSpan>? children,
    TextStyle? style,
    GestureRecognizer? recognizer,
    MouseCursor? mouseCursor,
    PointerEnterEventListener? onEnter,
    PointerExitEventListener? onExit,
    String? semanticsLabel,
    Locale? locale,
    bool? spellOut,
  }) =>
      TextSpan(
        text: text ?? this.text,
        children: children ?? this.children,
        style: style ?? this.style,
        recognizer: recognizer ?? this.recognizer,
        mouseCursor: mouseCursor ?? this.mouseCursor,
        onEnter: onEnter ?? this.onEnter,
        onExit: onExit ?? this.onExit,
        semanticsLabel: semanticsLabel ?? this.semanticsLabel,
        locale: locale ?? this.locale,
        spellOut: spellOut ?? this.spellOut,
      );
}

extension StringExt on String {
  String get withNewline => contains('\n') ? this : '$this\n';
}

extension ListEqualityExt<T> on List<T> {
  bool equals(List<T> other) =>
      length == other.length && indexed.every((e) => other[e.$1] == e.$2);
}

extension ListLineMetricsTextExt on List<LineMetrics> {
  /// Get the texts of all of the lines for the [LineMetrics]
  /// in the list using the given [TextPainter].
  List<String> getLineTexts(TextPainter painter, String text) =>
      map((line) => line.lineText(painter, text)).toList();
}

extension LineMetricsTextExt on LineMetrics {
  /// Get the text of the line for this [LineMetrics] using the given [TextPainter].
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
