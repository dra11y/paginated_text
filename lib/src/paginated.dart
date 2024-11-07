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

  static Future<Paginated> paginate(
    final PaginateData data,
    final Size layoutSize,
  ) async {
    final Size safeLayoutSize =
        layoutSize - Offset(_safePaddingHorizontal, 0) as Size;
    final textStyle = data.textStyle.copyWith(
      fontSize: (data.textStyle.fontSize ?? _defaultFontSize)
          .clamp(_minFontSize, _maxFontSize),
      height: data.textStyle.height ?? _defaultLineHeight,
    );

    final lineHeight = textStyle.height!;
    final linePixelHeight = lineHeight * textStyle.fontSize!;

    // Process drop cap lines
    final _DropCapLines? dropCapLines = await _processDropCapLines(
      data: data,
      textStyle: textStyle,
      safeLayoutSize: safeLayoutSize,
      linePixelHeight: linePixelHeight,
    );

    int offset = dropCapLines?.offset ?? 0;
    double remainingHeight =
        dropCapLines?.remainingHeight ?? safeLayoutSize.height;
    TextStyle? capTextStyle = dropCapLines?.capTextStyle;

    // Skip any mid-sentence whitespace after the drop cap lines.
    offset += _skipWhitespace(offset, data.text, newline: false);

    // Paginate the remaining text.
    final pages = _paginateRemainingText(
      data: data,
      textStyle: textStyle,
      safeLayoutSize: safeLayoutSize,
      linePixelHeight: linePixelHeight,
      offset: offset,
      remainingHeight: remainingHeight,
      dropCapLines: dropCapLines,
    );

    return Paginated._(
      text: data.text,
      textStyle: textStyle,
      capTextStyle: capTextStyle,
      layoutSize: safeLayoutSize,
      pages: pages,
    );
  }

  static Future<_DropCapLines?> _processDropCapLines({
    required final PaginateData data,
    required final TextStyle textStyle,
    required final Size safeLayoutSize,
    required final double linePixelHeight,
  }) async {
    final dropCapLines = data.dropCapLines.clamp(0, _maxDropCapLines);
    if (dropCapLines <= 1 || data.text.isEmpty) {
      return null;
    }

    final capChar = data.text[0];
    final effectiveCapStyle = data.capStyle ?? CapStyle.fromStyle(textStyle);

    final capMetrics = await computeCapMetrics(
      capStyle: effectiveCapStyle,
      textStyle: textStyle,
      lineHeight: linePixelHeight,
      textScaler: data.textScaler,
      capLines: dropCapLines,
    );

    final capTextStyle = capMetrics.capTextStyle.copyWith(
      height: _capHeight,
    );

    final capPainter = TextPainter(
      text: TextSpan(text: capChar, style: capTextStyle),
      textDirection: data.textDirection,
      maxLines: 1,
      textScaler: data.textScaler,
    )..layout();

    final capLinesText = data.text.substring(1);
    final capLinesPainter = TextPainter(
      text: TextSpan(text: capLinesText, style: textStyle),
      textDirection: data.textDirection,
      maxLines: dropCapLines,
      textScaler: data.textScaler,
    )..layout(maxWidth: safeLayoutSize.width - capPainter.width);

    final capLinesMetrics = capLinesPainter.computeLineMetrics();
    final capLines =
        capLinesMetrics.getLineTexts(capLinesPainter, capLinesText);

    int offset = capChar.length + capLines.join().length;
    offset += _processHardBreak(
      lines: capLines,
      hardPageBreak: data.hardPageBreak,
    );

    final pageText = capChar + capLines.join();
    final remainingHeight = safeLayoutSize.height - capLinesPainter.height;

    return _DropCapLines(
      capPainter: capPainter,
      capLinesPainter: capLinesPainter,
      capTextStyle: capTextStyle,
      capChar: capChar,
      capLines: capLines,
      capLinesText: pageText,
      offset: offset,
      remainingHeight: remainingHeight,
    );
  }

  static List<TextPage> _paginateRemainingText({
    required final PaginateData data,
    required final TextStyle textStyle,
    required final Size safeLayoutSize,
    required final double linePixelHeight,
    required final int offset,
    required final double remainingHeight,
    required final _DropCapLines? dropCapLines,
  }) {
    final List<TextPage> pages = [];
    int paginatedOffset = offset;
    double paginatedRemainingHeight = remainingHeight;
    String pagiantedPageText = dropCapLines?.capLinesText ?? '';
    final maxLinesPerPage = (safeLayoutSize.height / linePixelHeight).ceil();

    while (paginatedOffset < data.text.length) {
      final remainingText = data.text.substring(paginatedOffset);

      final textPainter = TextPainter(
        text: TextSpan(text: remainingText, style: textStyle),
        textDirection: data.textDirection,
        maxLines: maxLinesPerPage,
        textScaler: data.textScaler,
      )..layout(maxWidth: safeLayoutSize.width);

      final lineMetrics = textPainter.computeLineMetrics();

      final fitLineMetrics = lineMetrics.takeWhile((line) {
        return (line.baseline + line.height) < paginatedRemainingHeight;
      }).toList();

      final restLines = fitLineMetrics.getLineTexts(textPainter, remainingText);

      paginatedOffset += _processHardBreak(
          lines: restLines, hardPageBreak: data.hardPageBreak);

      if (fitLineMetrics.length < lineMetrics.length &&
          lineMetrics.sublist(fitLineMetrics.length).any(
              (lm) => lm.lineText(textPainter, remainingText).isNotEmpty)) {
        _processSoftBreak(
          offset: paginatedOffset,
          lines: restLines,
          breakType: data.breakType,
          maxLinesFromEndToBreakPage: data.maxLinesFromEndToBreakPage,
        );
      }

      final remainingPageText = restLines.join();
      pagiantedPageText += remainingPageText;

      final page = (pages.isEmpty && dropCapLines != null)
          ? DropCapTextPage(
              capPainter: dropCapLines.capPainter,
              capLinesPainter: dropCapLines.capLinesPainter,
              restTextPainter: textPainter,
              start: paginatedOffset,
              end: paginatedOffset + remainingPageText.length,
              layoutSize: safeLayoutSize,
              capLines: dropCapLines.capLines,
              capChar: dropCapLines.capChar,
              restLines: restLines,
              text: pagiantedPageText,
              endBreakType: data.breakType,
              capStyle: dropCapLines.capTextStyle,
              capAlign: TextAlign.center,
              textAlign: TextAlign.start,
              textDirection: data.textDirection,
              textStyle: textStyle,
              textScaler: data.textScaler,
            )
          : TextOnlyPage(
              breakType: data.breakType,
              painter: textPainter,
              start: paginatedOffset,
              end: paginatedOffset + remainingPageText.length,
              layoutSize: safeLayoutSize,
              lines: restLines,
              text: pagiantedPageText,
              textStyle: textStyle,
            );

      pages.add(page);

      paginatedOffset += remainingPageText.length;
      paginatedOffset +=
          _skipWhitespace(paginatedOffset, data.text, newline: true);

      paginatedRemainingHeight = safeLayoutSize.height;
      pagiantedPageText = '';
    }

    return pages;
  }

  static int _skipWhitespace(
    final int offset,
    final String text, {
    required final bool newline,
  }) {
    final substring = text.substring(offset.clamp(0, text.length - 1));
    final match = newline
        ? _whitespaceOrNewline.firstMatch(substring)
        : _whitespace.firstMatch(substring);
    if (match != null) {
      return match.end - match.start;
    }
    return 0;
  }

  static void _processSoftBreak({
    required final int offset,
    required final List<String> lines,
    required final PageBreakType breakType,
    required final int maxLinesFromEndToBreakPage,
  }) {
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

  static int _processHardBreak({
    required final List<String> lines,
    required final Pattern hardPageBreak,
  }) {
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

// Helper class to encapsulate drop cap lines data
class _DropCapLines {
  final TextPainter capPainter;
  final TextPainter capLinesPainter;
  final TextStyle capTextStyle;
  final String capChar;
  final List<String> capLines;
  final String capLinesText;
  final int offset;
  final double remainingHeight;

  _DropCapLines({
    required this.capPainter,
    required this.capLinesPainter,
    required this.capTextStyle,
    required this.capChar,
    required this.capLines,
    required this.capLinesText,
    required this.offset,
    required this.remainingHeight,
  });
}
