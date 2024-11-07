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

  static final _whitespace = RegExp(r'^[^\S\r\n]+');
  static final _whitespaceOrNewline = RegExp(r'^\s+');
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

    final layoutData = _LayoutData(
      data: data,
      textStyle: textStyle,
      safeLayoutSize: safeLayoutSize,
      linePixelHeight: linePixelHeight,
    );

    // Process drop cap lines
    final _DropCapLines? dropCapLines = await _processDropCapLines(layoutData);

    int offset = dropCapLines?.offset ?? 0;
    double remainingHeight =
        dropCapLines?.remainingHeight ?? safeLayoutSize.height;
    TextStyle? capTextStyle = dropCapLines?.capTextStyle;

    // Paginate the remaining text.
    final pages = _paginateRemainingText(
      layoutData: layoutData,
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

  static Future<_DropCapLines?> _processDropCapLines(
      final _LayoutData layoutData) async {
    final dropCapLines =
        layoutData.data.dropCapLines.clamp(0, _maxDropCapLines);
    if (dropCapLines <= 1 || layoutData.data.text.trim().isEmpty) {
      return null;
    }

    // Since we have a drop cap, skip any whitespace at the beginning.
    int offset = _skipWhitespace(0, layoutData.data.text, newline: true);

    final capChar = layoutData.data.text[offset];
    final effectiveCapStyle =
        layoutData.data.capStyle ?? CapStyle.fromStyle(layoutData.textStyle);

    final capMetrics = await computeCapMetrics(
      capStyle: effectiveCapStyle,
      textStyle: layoutData.textStyle,
      lineHeight: layoutData.linePixelHeight,
      textScaler: layoutData.data.textScaler,
      capLines: dropCapLines,
    );

    final capTextStyle = capMetrics.capTextStyle.copyWith(
      height: _capHeight,
    );

    final capPainter = TextPainter(
      text: TextSpan(text: capChar, style: capTextStyle),
      textDirection: layoutData.data.textDirection,
      maxLines: 1,
      textScaler: layoutData.data.textScaler,
    )..layout();

    offset += capChar.length;
    final capLinesText = layoutData.data.text.substring(offset);

    final capLinesPainter = TextPainter(
      text: TextSpan(text: capLinesText, style: layoutData.textStyle),
      textDirection: layoutData.data.textDirection,
      maxLines: dropCapLines,
      textScaler: layoutData.data.textScaler,
    )..layout(maxWidth: layoutData.safeLayoutSize.width - capPainter.width);

    final capLinesMetrics = capLinesPainter.computeLineMetrics();
    final capLines =
        capLinesMetrics.getLineTexts(capLinesPainter, capLinesText);

    offset += capLines.join().length;
    offset += _processHardBreak(
      lines: capLines,
      hardPageBreak: layoutData.data.hardPageBreak,
    );

    final pageText = capChar + capLines.join();
    final remainingHeight =
        layoutData.safeLayoutSize.height - capLinesPainter.height;

    // Skip any mid-sentence whitespace after the drop cap lines.
    offset += _skipWhitespace(offset, layoutData.data.text, newline: false);

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
    required final _LayoutData layoutData,
    required final int offset,
    required final double remainingHeight,
    required final _DropCapLines? dropCapLines,
  }) {
    final List<TextPage> pages = [];
    int paginatedOffset = offset;
    double paginatedRemainingHeight = remainingHeight;
    bool isFirstPage = true;
    final maxLinesPerPage =
        (layoutData.safeLayoutSize.height / layoutData.linePixelHeight).ceil();

    while (paginatedOffset < layoutData.data.text.length) {
      final initialPageText =
          isFirstPage ? (dropCapLines?.capLinesText ?? '') : '';

      final remainingText = layoutData.data.text.substring(paginatedOffset);

      final textPainter = TextPainter(
        text: TextSpan(text: remainingText, style: layoutData.textStyle),
        textDirection: layoutData.data.textDirection,
        maxLines: maxLinesPerPage,
        textScaler: layoutData.data.textScaler,
      )..layout(maxWidth: layoutData.safeLayoutSize.width);

      final lineMetrics = textPainter.computeLineMetrics();

      final fitLineMetrics = lineMetrics.takeWhile((line) {
        return (line.baseline + line.height) < paginatedRemainingHeight;
      }).toList();

      final restLines = fitLineMetrics.getLineTexts(textPainter, remainingText);

      paginatedOffset += _processHardBreak(
          lines: restLines, hardPageBreak: layoutData.data.hardPageBreak);

      if (fitLineMetrics.length < lineMetrics.length &&
          lineMetrics.sublist(fitLineMetrics.length).any(
              (lm) => lm.lineText(textPainter, remainingText).isNotEmpty)) {
        _processSoftBreak(
          offset: paginatedOffset,
          lines: restLines,
          breakType: layoutData.data.breakType,
          maxLinesFromEndToBreakPage:
              layoutData.data.maxLinesFromEndToBreakPage,
        );
      }

      final remainingPageText = restLines.join();
      final paginatedText = initialPageText + remainingPageText;

      final page = (pages.isEmpty && dropCapLines != null)
          ? DropCapTextPage(
              capPainter: dropCapLines.capPainter,
              capLinesPainter: dropCapLines.capLinesPainter,
              restTextPainter: textPainter,
              start: paginatedOffset,
              end: paginatedOffset + remainingPageText.length,
              layoutSize: layoutData.safeLayoutSize,
              capLines: dropCapLines.capLines,
              capChar: dropCapLines.capChar,
              restLines: restLines,
              text: paginatedText,
              endBreakType: layoutData.data.breakType,
              capStyle: dropCapLines.capTextStyle,
              capAlign: TextAlign.center,
              textAlign: TextAlign.start,
              textDirection: layoutData.data.textDirection,
              textStyle: layoutData.textStyle,
              textScaler: layoutData.data.textScaler,
            )
          : TextOnlyPage(
              breakType: layoutData.data.breakType,
              painter: textPainter,
              start: paginatedOffset,
              end: paginatedOffset + remainingPageText.length,
              layoutSize: layoutData.safeLayoutSize,
              lines: restLines,
              text: paginatedText,
              textStyle: layoutData.textStyle,
            );

      pages.add(page);

      paginatedOffset += remainingPageText.length;
      paginatedOffset +=
          _skipWhitespace(paginatedOffset, layoutData.data.text, newline: true);

      paginatedRemainingHeight = layoutData.safeLayoutSize.height;
      isFirstPage = false;
    }

    return pages;
  }

  static int _skipWhitespace(
    final int offset,
    final String text, {
    required final bool newline,
  }) {
    if (text.isEmpty) {
      return 0;
    }
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

// Helper class to encapsulate layout data
class _LayoutData {
  final PaginateData data;
  final TextStyle textStyle;
  final Size safeLayoutSize;
  final double linePixelHeight;

  const _LayoutData({
    required this.data,
    required this.textStyle,
    required this.safeLayoutSize,
    required this.linePixelHeight,
  });
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
