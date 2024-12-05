import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'cap_style.dart';
import 'page_break_type.dart';

final class PaginateData {
  final String text;
  final int dropCapLines;
  final TextStyle textStyle;
  final CapStyle? capStyle;
  final bool parseMarkdown;
  final TextScaler textScaler;
  final TextDirection textDirection;
  final PageBreakType pageBreakType;
  final Pattern hardPageBreak;
  final int maxLinesFromEndToBreakPage;

  const PaginateData({
    required this.text,
    required this.dropCapLines,
    required this.textStyle,
    this.capStyle,
    this.parseMarkdown = false,
    this.textScaler = TextScaler.noScaling,
    this.textDirection = TextDirection.ltr,
    this.pageBreakType = PageBreakType.fragment,
    this.hardPageBreak = '<page>',
    this.maxLinesFromEndToBreakPage = 5,
  });

  @override
  int get hashCode => Object.hash(
        text,
        dropCapLines,
        textStyle,
        capStyle,
        parseMarkdown,
        pageBreakType,
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
      other.parseMarkdown == parseMarkdown &&
      other.pageBreakType == pageBreakType &&
      other.hardPageBreak == hardPageBreak &&
      other.textScaler == textScaler &&
      other.textDirection == textDirection &&
      other.maxLinesFromEndToBreakPage == maxLinesFromEndToBreakPage;

  PaginateData copyWith({
    String? text,
    int? dropCapLines,
    TextStyle? textStyle,
    CapStyle? capStyle,
    bool? parseMarkdown,
    TextScaler? textScaler,
    TextDirection? textDirection,
    PageBreakType? pageBreakType,
    String? hardPageBreak,
    int? maxLinesFromEndToBreakPage,
  }) =>
      PaginateData(
        text: text ?? this.text,
        dropCapLines: dropCapLines ?? this.dropCapLines,
        textStyle: textStyle ?? this.textStyle,
        capStyle: capStyle ?? this.capStyle,
        parseMarkdown: parseMarkdown ?? this.parseMarkdown,
        textScaler: textScaler ?? this.textScaler,
        textDirection: textDirection ?? this.textDirection,
        pageBreakType: pageBreakType ?? this.pageBreakType,
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
    parseMarkdown: $parseMarkdown,
    textScaler: $textScaler,
    textDirection: $textDirection,
    pageBreakType: $pageBreakType,
    hardPageBreak: $hardPageBreak,
    maxLinesFromEndToBreakPage: $maxLinesFromEndToBreakPage,
  )''';
}
