import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'compute_cap_text_style.dart';
import 'extensions.dart';

import 'page_break_type.dart';

sealed class TextPage {
  int get start;
  int get end;
  String get text;
  Size get layoutSize;

  Widget widget(BuildContext context);

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
  @override
  final Size layoutSize;
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
    required this.layoutSize,
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
      other.layoutSize == layoutSize &&
      other.capChar == capChar &&
      other.text == text &&
      other.endBreakType == endBreakType &&
      other.capLines.equals(capLines) &&
      other.restLines.equals(restLines);

  @override
  int get hashCode => Object.hashAll([
        start,
        end,
        layoutSize,
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
    layoutSize: $layoutSize,
    text.length: ${text.length},
    capChar: $capChar,
    capLines: ${capLines.debugString()},
    restLines: ${restLines.debugString()},
  )''';

  @override
  Widget widget(BuildContext context) {
    final baselineOffset = Offset(
        0, (capLines.length - 1) * textStyle.height! * textStyle.fontSize!);
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Container(
                clipBehavior: Clip.none,
                width: capPainter.width,
                transform: Transform.translate(
                  offset: baselineOffset,
                ).transform,
                child: Text.rich(
                  TextSpan(
                    text: capChar,
                    style: capStyle,
                  ),
                  overflow: TextOverflow.visible,
                  textHeightBehavior: TextHeightBehavior(
                    applyHeightToFirstAscent: true,
                  ),
                  textDirection: textDirection,
                  softWrap: false,
                  textAlign: capAlign,
                  maxLines: 1,
                  textScaler: textScaler,
                ),
              ),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: textStyle,
                    children: [
                      for (final line in capLines)
                        TextSpan(text: line.withNewline),
                    ],
                  ),
                  overflow: TextOverflow.clip,
                  softWrap: false,
                  maxLines: capLines.length,
                  textDirection: textDirection,
                  textAlign: textAlign,
                  textScaler: textScaler,
                ),
              ),
            ],
          ),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: textStyle,
                children: [
                  for (final line in restLines)
                    TextSpan(text: line.withNewline),
                ],
              ),
              overflow: TextOverflow.clip,
              softWrap: false,
              textAlign: restTextPainter.textAlign,
              textDirection: restTextPainter.textDirection,
              textScaler: restTextPainter.textScaler,
            ),
          ),
        ],
      ),
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
  final Size layoutSize;
  @override
  final String text;
  final TextStyle textStyle;

  final List<String> lines;

  static TextOnlyPage blank({required Size layoutSize}) => TextOnlyPage(
        breakType: PageBreakType.word,
        painter: _emptyTextPainter,
        start: 0,
        end: 0,
        layoutSize: layoutSize,
        textStyle: const TextStyle(),
        lines: [''],
        text: '',
      );

  const TextOnlyPage({
    required this.breakType,
    required this.painter,
    required this.start,
    required this.end,
    required this.layoutSize,
    required this.lines,
    required this.text,
    required this.textStyle,
  });

  @override
  bool operator ==(Object other) =>
      other is TextOnlyPage &&
      other.painter.size == painter.size &&
      other.breakType == breakType &&
      other.start == start &&
      other.end == end &&
      other.layoutSize == layoutSize &&
      other.text == text &&
      other.textStyle == textStyle &&
      other.lines.equals(other.lines);

  @override
  int get hashCode => Object.hashAll([
        breakType,
        start,
        end,
        layoutSize,
        text,
        textStyle,
        painter.size,
        ...lines,
      ]);

  @override
  String toString() => '''
  ${objectRuntimeType(this, 'TextOnlyPage')}(
    breakType: $breakType,
    start: $start,
    end: $end,
    layoutSize: $layoutSize,
    text.length: ${text.length},
    lines: ${lines.debugString()},
  )''';

  @override
  Widget widget(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: textStyle,
        children: [
          for (final line in lines) TextSpan(text: line.withNewline),
        ],
      ),
      overflow: TextOverflow.clip,
      softWrap: false,
      textAlign: painter.textAlign,
      textDirection: painter.textDirection,
      textScaler: painter.textScaler,
    );
  }
}
