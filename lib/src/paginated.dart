import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:paginated_text/src/cap_style.dart';
import 'package:paginated_text/src/paginate_data.dart';
import 'extensions.dart';

import 'compute_cap_text_style.dart';
import 'page_break_type.dart';
import 'text_page.dart';

final class Paginated {
  final String text;
  final TextStyle textStyle;
  final TextStyle? capTextStyle;
  final Size layoutSize;
  final List<TextPage> pages;

  static final _whitespace = RegExp(r'^[^\S\r\n]');
  static final _whitespaceOrNewline = RegExp(r'^[^\S]');
  static const double _minFontSize = 10.0;
  static const double _maxFontSize = 200.0;
  static const double _defaultFontSize = 16.0;
  static const double _defaultLineHeight = 1.4;
  static const double _safePaddingHorizontal = 20.0;
  // The line height used to layout the drop cap so it gets properly aligned by `Row`.
  static const double _capHeight = 0.001;
  static const int _maxDropCapLines = 5;

  const Paginated._({
    required this.text,
    required this.textStyle,
    required this.capTextStyle,
    required this.layoutSize,
    required this.pages,
  });

  TextPage page(int index) => pages.isNotEmpty
      ? pages[index.clamp(0, pages.length - 1)]
      : TextOnlyPage.blank(layoutSize: layoutSize);

  @override
  bool operator ==(Object other) =>
      other is Paginated &&
      other.text == text &&
      other.textStyle == textStyle &&
      other.capTextStyle == capTextStyle &&
      other.layoutSize == layoutSize &&
      other.pages.equals(pages);

  @override
  int get hashCode => Object.hashAll([
        text,
        textStyle,
        capTextStyle,
        layoutSize,
        ...pages,
      ]);

  static Future<Paginated> paginate(PaginateData data, Size layoutSize) async {
    final Size safeLayoutSize =
        layoutSize - Offset(_safePaddingHorizontal, 0) as Size;
    final textStyle = data.textStyle.copyWith(
      fontSize: (data.textStyle.fontSize ?? _defaultFontSize)
          .clamp(_minFontSize, _maxFontSize),
      height: data.textStyle.height ?? _defaultLineHeight,
    );
    final dropCapLines = data.dropCapLines.clamp(0, _maxDropCapLines);

    final List<TextPage> pages = [];
    double remainingHeight = safeLayoutSize.height;
    final lineHeight = textStyle.height!;
    final linePixelHeight = lineHeight * textStyle.fontSize!;
    int offset = 0;
    List<String>? capLines;
    String? capChar;
    TextPainter? capPainter;
    TextPainter? capLinesPainter;
    String pageText = '';
    TextStyle? capTextStyle;

    final maxLinesPerPage = (safeLayoutSize.height / linePixelHeight).ceil();

    if (dropCapLines > 1) {
      capChar = data.text[0];
      final effectiveCapStyle = data.capStyle ?? CapStyle.fromStyle(textStyle);
      final capMetrics = await computeCapMetrics(
        capStyle: effectiveCapStyle,
        textStyle: textStyle,
        lineHeight: linePixelHeight,
        textScaler: data.textScaler,
        capLines: dropCapLines,
      );

      capTextStyle = capMetrics.capTextStyle.copyWith(
        height: _capHeight,
      );
      capPainter = TextPainter(
        text: TextSpan(text: capChar, style: capTextStyle),
        textDirection: data.textDirection,
        maxLines: 1,
        textScaler: data.textScaler,
      )..layout();

      final capLinesText = data.text.substring(1);
      capLinesPainter = TextPainter(
        text: TextSpan(text: capLinesText, style: textStyle),
        textDirection: data.textDirection,
        maxLines: dropCapLines,
        textScaler: data.textScaler,
      )..layout(maxWidth: safeLayoutSize.width - capPainter.width);

      remainingHeight -= capLinesPainter.height;

      final capLinesMetrics = capLinesPainter.computeLineMetrics();

      capLines = capLinesMetrics.getLineTexts(capLinesPainter, capLinesText);

      offset += _processHardBreak(capLines, data.hardPageBreak);

      pageText = capChar + capLines.join();
      offset += pageText.length;
    }

    offset += _skipWhitespace(offset, data.text, skipNewline: false);

    while (offset < data.text.length - 1) {
      final remainingText = data.text.substring(offset);

      final textPainter = TextPainter(
        text: TextSpan(text: remainingText, style: textStyle),
        textDirection: data.textDirection,
        maxLines: maxLinesPerPage,
        textScaler: data.textScaler,
      )..layout(maxWidth: safeLayoutSize.width);

      final lineMetrics = textPainter.computeLineMetrics();

      final fitLineMetrics = lineMetrics.takeWhile((line) {
        return (line.baseline + line.height) < remainingHeight;
      }).toList();

      final restLines = fitLineMetrics.getLineTexts(textPainter, remainingText);

      offset += _processHardBreak(restLines, data.hardPageBreak);

      if (fitLineMetrics.length < lineMetrics.length &&
          lineMetrics.sublist(fitLineMetrics.length).any(
              (lm) => lm.lineText(textPainter, remainingText).isNotEmpty)) {
        _processSoftBreak(
          offset,
          restLines,
          data.breakType,
          data.maxLinesFromEndToBreakPage,
        );
      }

      final remainingPageText = restLines.join();
      pageText += remainingPageText;

      final isDropCapPage = pages.isEmpty &&
          capPainter != null &&
          capLines != null &&
          capLinesPainter != null &&
          capChar != null &&
          capTextStyle != null;

      final page = isDropCapPage
          ? DropCapTextPage(
              capPainter: capPainter,
              capLinesPainter: capLinesPainter,
              restTextPainter: textPainter,
              start: offset,
              end: offset + remainingPageText.length,
              layoutSize: safeLayoutSize,
              capLines: capLines,
              capChar: capChar,
              restLines: restLines,
              text: pageText,
              endBreakType: data.breakType,
              capStyle: capTextStyle,
              capAlign: TextAlign.center,
              textAlign: TextAlign.start,
              textDirection: data.textDirection,
              textStyle: textStyle,
              textScaler: data.textScaler,
            )
          : TextOnlyPage(
              breakType: data.breakType,
              painter: textPainter,
              start: offset,
              end: offset + remainingPageText.length,
              layoutSize: safeLayoutSize,
              lines: restLines,
              text: pageText,
              textStyle: textStyle,
            );

      pages.add(page);

      offset += remainingPageText.length;
      offset += _skipWhitespace(offset, data.text, skipNewline: true);

      remainingHeight = safeLayoutSize.height;
      pageText = '';
    }

    return Paginated._(
      text: data.text,
      textStyle: textStyle,
      capTextStyle: capTextStyle,
      layoutSize: safeLayoutSize,
      pages: pages,
    );
  }

  static int _skipWhitespace(final int offset, final String text,
      {required bool skipNewline}) {
    final substring = text.substring(offset.clamp(0, text.length - 1));
    final match = skipNewline
        ? _whitespaceOrNewline.firstMatch(substring)
        : _whitespace.firstMatch(substring);
    if (match != null) {
      return match.end - match.start;
    }
    return 0;
  }

  static void _processSoftBreak(
    final int offset,
    final List<String> lines,
    final PageBreakType breakType,
    final int maxLinesFromEndToBreakPage,
  ) {
    final smallestBreakIndex = PageBreakType.values.indexOf(breakType);

    for (int i = lines.length - 1;
        i >= max(1, lines.length - maxLinesFromEndToBreakPage);
        i--) {
      for (int j = PageBreakType.values.length - 1;
          j >= smallestBreakIndex;
          j--) {
        final currentBreakType = PageBreakType.values[j];

        final line = lines[i];
        final match = currentBreakType.regex.allMatches(line).lastOrNull;
        if (match != null) {
          lines[i] = line.substring(0, match.end);
          if (i < lines.length - 1) {
            lines.removeRange(i + 1, lines.length);
          }
          return;
        }
      }
    }
  }

  static int _processHardBreak(
    final List<String> lines,
    final Pattern hardPageBreak,
  ) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final match = hardPageBreak.allMatches(line).firstOrNull;
      if (match == null) {
        continue;
      }
      lines[i] = line.substring(0, match.start);
      if (i < lines.length - 1) {
        lines.removeRange(i + 1, lines.length);
      }
      return match.end - match.start;
    }

    return 0;
  }

  @override
  String toString() => '''
  ${objectRuntimeType(this, 'PaginatedText')}(
    text.length: ${text.length},
    textStyle: $textStyle,
    capTextStyle: $capTextStyle,
    layoutSize: $layoutSize,
    pages: $pages,
  )''';
}
