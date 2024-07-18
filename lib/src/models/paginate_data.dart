import 'package:flutter/material.dart';

/// Determines how the page break should occur during pagination.
enum PageBreakType {
  /// Break pages on the last visible word of the page.
  word,

  /// Attempt to break pages at a period, comma, semicolon, or em dash (-- / —).
  sentenceFragment,

  /// Attempt to break pages at the end of a sentence.
  sentence,

  /// Attempt to break at paragraphs (two consecutive newlines).
  paragraph;

  RegExp get regex {
    final regex = _regexMap[this];
    if (regex == null) {
      throw ArgumentError.value(this, 'regex', 'has no');
    }
    return regex;
  }

  static final Map<PageBreakType, RegExp> _regexMap = {
    PageBreakType.sentenceFragment: RegExp(r'([.,;:—–]|--)\s*'),
    PageBreakType.sentence: RegExp(r'\.[^a-z]*', caseSensitive: false),
    PageBreakType.paragraph: RegExp(r'[\r\n\s*]{2,}'),
  };
}

/// User-provided text and configuration of how the text should be formatted and paginated.
class PaginateData {
  /// The whole text to be paginated. The initial letter will be a drop cap
  /// if `dropCapLines` > 0.
  final String text;

  /// The `TextStyle` of the body text. This is required to paginate the
  /// text without a `BuildContext`.
  final TextStyle style;

  /// Number of lines high the drop cap should be. If 0, the text will
  /// not have a drop cap.
  final int dropCapLines;

  /// The style, if different than `style`, for the drop cap.
  final TextStyle? dropCapStyle;

  /// Extra padding to add around drop cap letter.
  final EdgeInsets dropCapPadding;

  /// Attempts to split pages at the specified point.
  /// Falls back to the next lower `PageBreakType` if not found within `breakLines`
  /// of the last visible line of the page.
  final PageBreakType pageBreakType;

  /// Forces a page break when encountering this pattern.
  /// If set to an empty string, there are no manual page breaks.
  /// Defaults to "<page>".
  final Pattern hardPageBreak;

  /// Considers only this many lines from the last visible for `pageBreak`.
  /// Defaults to 1 (the last line only).
  /// If `pageBreak` is not encountered on these lines, falls back to `PageBreak.word`.
  final int breakLines;

  /// Pass in the text direction to be used. Defaults to `TextDirection.ltr`.
  final TextDirection textDirection;

  /// Pass in the text scaler to be used. Defaults to `TextScaler.noScaling`.
  final TextScaler textScaler;

  /// The amount (in width or height) the layout size can change before
  /// the text should be repaginated.
  final double resizeTolerance;

  /// Whether or not to parse inline markdown.
  final bool parseInlineMarkdown;

  const PaginateData({
    required this.text,
    required this.style,
    required this.dropCapLines,
    this.dropCapStyle,
    this.dropCapPadding = EdgeInsets.zero,
    this.pageBreakType = PageBreakType.paragraph,
    this.hardPageBreak = r'<page>',
    this.breakLines = 1,
    this.textDirection = TextDirection.ltr,
    this.textScaler = TextScaler.noScaling,
    this.resizeTolerance = 2.0,
    this.parseInlineMarkdown = false,
  });

  /// Make a copy of this object with specified modified properties.
  PaginateData copyWith({
    String? text,
    TextStyle? style,
    int? dropCapLines,
    TextStyle? dropCapStyle,
    bool clearDropCapStyle = false,
    TextDirection? textDirection,
    TextScaler? textScaler,
    double? resizeTolerance,
  }) =>
      PaginateData(
        text: text ?? this.text,
        style: style ?? this.style,
        dropCapStyle:
            dropCapStyle ?? (clearDropCapStyle ? null : this.dropCapStyle),
        dropCapLines: dropCapLines ?? this.dropCapLines,
        textDirection: textDirection ?? this.textDirection,
        textScaler: textScaler ?? this.textScaler,
        resizeTolerance: resizeTolerance ?? this.resizeTolerance,
      );

  @override
  int get hashCode => Object.hash(text, style, dropCapLines, dropCapStyle,
      textDirection, textScaler, resizeTolerance);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PaginateData &&
          text == other.text &&
          style == other.style &&
          dropCapLines == other.dropCapLines &&
          dropCapStyle == other.dropCapStyle &&
          pageBreakType == other.pageBreakType &&
          breakLines == other.breakLines &&
          textDirection == other.textDirection &&
          textScaler == other.textScaler &&
          resizeTolerance == other.resizeTolerance);

  @override
  String toString() => [
        '$runtimeType(',
        '    text: $text',
        '    style: $style',
        '    dropCapLines: $dropCapLines',
        '    dropCapStyle: $dropCapStyle',
        '    dropCapPadding: $dropCapPadding',
        '    pageBreakType: $pageBreakType',
        '    hardPageBreak: $hardPageBreak',
        '    breakLines: $breakLines',
        '    textDirection: $textDirection',
        '    textScaler: $textScaler',
        '    resizeTolerance: $resizeTolerance',
        '    parseInlineMarkdown: $parseInlineMarkdown',
        ')',
      ].join('\n');
}
