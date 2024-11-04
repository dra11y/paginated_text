import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'cap_style.dart';
import 'page_break_type.dart';

final class PaginateData {
  final String text;
  final int dropCapLines;
  final TextStyle textStyle;
  final CapStyle? capStyle;
  final TextScaler textScaler;
  final TextDirection textDirection;
  final PageBreakType breakType;
  final Pattern hardPageBreak;
  final int maxLinesFromEndToBreakPage;

  const PaginateData({
    required this.text,
    required this.dropCapLines,
    required this.textStyle,
    this.capStyle,
    this.textScaler = TextScaler.noScaling,
    this.textDirection = TextDirection.ltr,
    this.breakType = PageBreakType.fragment,
    this.hardPageBreak = '<page>',
    this.maxLinesFromEndToBreakPage = 5,
  });

  @override
  int get hashCode => Object.hash(
        text,
        dropCapLines,
        textStyle,
        capStyle,
        breakType,
        hardPageBreak,
        textScaler,
        textDirection,
        maxLinesFromEndToBreakPage,
      );

  @override
  bool operator ==(Object other) =>
      other is PaginateData &&
      other.text == text &&
      other.dropCapLines == dropCapLines &&
      other.textStyle == textStyle &&
      other.capStyle == capStyle &&
      other.breakType == breakType &&
      other.hardPageBreak == hardPageBreak &&
      other.textScaler == textScaler &&
      other.textDirection == textDirection &&
      other.maxLinesFromEndToBreakPage == maxLinesFromEndToBreakPage;

  PaginateData copyWith({
    String? text,
    int? dropCapLines,
    TextStyle? textStyle,
    CapStyle? capStyle,
    TextScaler? textScaler,
    TextDirection? textDirection,
    PageBreakType? breakType,
    String? hardPageBreak,
    int? maxLinesFromEndToBreakPage,
  }) =>
      PaginateData(
        text: text ?? this.text,
        dropCapLines: dropCapLines ?? this.dropCapLines,
        textStyle: textStyle ?? this.textStyle,
        capStyle: capStyle ?? this.capStyle,
        textScaler: textScaler ?? this.textScaler,
        textDirection: textDirection ?? this.textDirection,
        breakType: breakType ?? this.breakType,
        hardPageBreak: hardPageBreak ?? this.hardPageBreak,
        maxLinesFromEndToBreakPage:
            maxLinesFromEndToBreakPage ?? this.maxLinesFromEndToBreakPage,
      );

  @override
  String toString() => '''
  ${objectRuntimeType(this, 'PaginateData')}(
    text: $text,
    dropCapLines: $dropCapLines,
    textStyle: $textStyle,
    capStyle: $capStyle,
    textScaler: $textScaler,
    textDirection: $textDirection,
    breakType: $breakType,
    hardPageBreak: $hardPageBreak,
    maxLinesFromEndToBreakPage: $maxLinesFromEndToBreakPage,
  )''';
}
