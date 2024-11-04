import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'extensions.dart';

import 'page_break_type.dart';

sealed class TextPage {
  int get start;
  int get end;
  String get text;

  Widget build();

  const TextPage();
}

final class DropCapTextPage extends TextPage {
  final TextPainter capPainter;
  final TextPainter capLinesPainter;
  final TextPainter restTextPainter;
  final PageBreakType endBreakType;

  @override
  final int start;
  @override
  final int end;
  final String capChar;
  final List<String> capLines;
  final List<String> restLines;
  @override
  final String text;
  final TextStyle capStyle;
  final TextStyle textStyle;
  final TextDirection textDirection;
  final TextScaler textScaler;
  final TextAlign capAlign;
  final TextAlign textAlign;

  const DropCapTextPage({
    required this.capPainter,
    required this.capLinesPainter,
    required this.restTextPainter,
    required this.start,
    required this.end,
    required this.capChar,
    required this.capStyle,
    required this.capLines,
    required this.textStyle,
    required this.textDirection,
    required this.textScaler,
    required this.capAlign,
    required this.textAlign,
    required this.restLines,
    required this.text,
    required this.endBreakType,
  });

  @override
  bool operator ==(Object other) =>
      other is DropCapTextPage &&
      other.capPainter.size == capPainter.size &&
      other.capLinesPainter.size == capLinesPainter.size &&
      other.restTextPainter.size == restTextPainter.size &&
      other.capStyle == capStyle &&
      other.textStyle == textStyle &&
      other.textDirection == textDirection &&
      other.textScaler == textScaler &&
      other.capAlign == capAlign &&
      other.textAlign == textAlign &&
      other.start == start &&
      other.end == end &&
      other.capChar == capChar &&
      other.text == text &&
      other.endBreakType == endBreakType &&
      other.capLines.equals(capLines) &&
      other.restLines.equals(restLines);

  @override
  int get hashCode => Object.hashAll([
        start,
        end,
        capChar,
        text,
        endBreakType,
        capStyle,
        textStyle,
        textDirection,
        textScaler,
        capPainter.size,
        capLinesPainter.size,
        restTextPainter.size,
        ...capLines,
        ...restLines,
      ]);

  @override
  String toString() => '''
  ${objectRuntimeType(this, 'DropCapTextPage')}(
    start: $start,
    end: $end,
    text.length: ${text.length},
    capChar: $capChar,
    capLines: ${capLines.debugString()},
    restLines: ${restLines.debugString()},
  )''';

  @override
  Widget build() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedOverflowBox(
              size: capPainter.size,
              alignment: Alignment.topLeft,
              child: Container(
                clipBehavior: Clip.none,
                width: capPainter.width,
                // height: capHeight + (textBaseline - capBaseline),
                // transform: Transform.translate(
                //   offset: Offset(0, textBaseline - capBaseline),
                // ).transform,
                child: Text.rich(
                  TextSpan(
                    text: capChar,
                    style: capStyle,
                  ),
                  overflow: TextOverflow.visible,
                  textDirection: textDirection,
                  textAlign: capAlign,
                  maxLines: 1,
                  textScaler: textScaler,
                ),
              ),
            ),
            SizedBox(
              width: capLinesPainter.width,
              child: Text.rich(
                TextSpan(
                  text: capLines.join(),
                  style: textStyle,
                ),
                overflow: TextOverflow.clip,
                maxLines: capLines.length,
                textDirection: textDirection,
                textAlign: textAlign,
                textScaler: textScaler,
              ),
            ),
          ],
        ),
        Text.rich(
          TextSpan(
            text: restLines.join(),
            style: textStyle,
          ),
          overflow: TextOverflow.clip,
          textAlign: textAlign,
          textDirection: textDirection,
          textScaler: textScaler,
          style: textStyle,
        ),
      ],
    );
  }
}

final _emptyTextPainter =
    TextPainter(text: TextSpan(text: ''), textDirection: TextDirection.ltr)
      ..layout();

final class TextOnlyPage extends TextPage {
  final PageBreakType breakType;
  final TextPainter painter;

  @override
  final int start;
  @override
  final int end;
  @override
  final String text;

  final List<String> lines;

  static TextOnlyPage blank() => TextOnlyPage(
        breakType: PageBreakType.word,
        painter: _emptyTextPainter,
        start: 0,
        end: 0,
        lines: [''],
        text: '',
      );

  const TextOnlyPage({
    required this.breakType,
    required this.painter,
    required this.start,
    required this.end,
    required this.lines,
    required this.text,
  });

  @override
  bool operator ==(Object other) =>
      other is TextOnlyPage &&
      other.painter.size == painter.size &&
      other.breakType == breakType &&
      other.start == start &&
      other.end == end &&
      other.text == text &&
      other.lines.equals(other.lines);

  @override
  int get hashCode => Object.hashAll([
        breakType,
        start,
        end,
        text,
        painter.size,
        ...lines,
      ]);

  @override
  String toString() => '''
  ${objectRuntimeType(this, 'TextOnlyPage')}(
    breakType: $breakType,
    start: $start,
    end: $end,
    text.length: ${text.length},
    lines: ${lines.debugString()},
  )''';

  @override
  Widget build() {
    throw UnimplementedError();
  }
}
