import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:paginated_text/src/cap_style.dart';
import 'package:paginated_text/src/paginate_data.dart';
import 'extensions.dart';

import 'compute_cap_text_style.dart';
import 'page_break_type.dart';
import 'text_page.dart';

final _whitespace = RegExp(r'^([^\S\r\n](?!\s))');
final _whitespaceOrNewline = RegExp(r'^(\s*\n|\s(?!\s))');

final class Paginated {
  final String text;
  final TextStyle textStyle;
  final TextStyle? capTextStyle;
  final Size layoutSize;
  final List<TextPage> pages;

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
    final Size safeLayoutSize = layoutSize - Offset(20, 0) as Size;
    final textStyle = data.textStyle.copyWith(
      fontSize: (data.textStyle.fontSize ?? 16).clamp(10, 200),
      height: data.textStyle.height ?? 1.4,
    );
    final dropCapLines = data.dropCapLines.clamp(0, 5);

    final List<TextPage> pages = [];
    double remainingHeight = safeLayoutSize.height;
    final lineHeight = textStyle.height!;
    final linePixelHeight = lineHeight * textStyle.fontSize!;
    int offset = 0;
    final List<String> capLines = [];
    String? capChar;
    TextPainter? capPainter;
    TextPainter? capLinesPainter;
    String pageText = '';
    TextStyle? capTextStyle;

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
        height: 0.001,
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
        // textHeightBehavior: TextHeightBehavior(
        //   applyHeightToFirstAscent: true,
        //   applyHeightToLastDescent: true,
        //   leadingDistribution: TextLeadingDistribution.even,
        // ),
      )..layout(maxWidth: safeLayoutSize.width - capPainter.width);

      remainingHeight -= capLinesPainter.height;

      final capLinesMetrics = capLinesPainter.computeLineMetrics();

      capLines
          .addAll(capLinesMetrics.getLineTexts(capLinesPainter, capLinesText));

      offset = _processHardBreak(capLines, data.hardPageBreak, offset);

      pageText = capChar + capLines.join();
      offset += pageText.length;
    }

    final maxLinesPerPage = (safeLayoutSize.height / linePixelHeight).ceil();

    offset = _skipWhitespace(offset, data.text, skipNewline: false);

    while (offset < data.text.length - 1) {
      final remainingText = data.text.substring(offset);

      final textPainter = TextPainter(
        text: TextSpan(text: remainingText, style: textStyle),
        textDirection: data.textDirection,
        maxLines: maxLinesPerPage,
        textScaler: data.textScaler,
        // textHeightBehavior: TextHeightBehavior(
        //   applyHeightToFirstAscent: true,
        //   applyHeightToLastDescent: true,
        //   leadingDistribution: TextLeadingDistribution.even,
        // ),
      )..layout(maxWidth: safeLayoutSize.width);

      final lineMetrics = textPainter.computeLineMetrics().takeWhile((line) {
        return (line.baseline + line.height) < remainingHeight;
      }).toList();

      final restLines = lineMetrics.getLineTexts(textPainter, remainingText);

      offset = _processHardBreak(restLines, data.hardPageBreak, offset);
      _processSoftBreak(
          restLines, data.breakType, data.maxLinesFromEndToBreakPage);

      final remainingPageText = restLines.join();
      pageText += remainingPageText;

      final isDropCapPage = pages.isEmpty &&
          capPainter != null &&
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
      offset = _skipWhitespace(offset, data.text);
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
      {bool skipNewline = true}) {
    int newOffset = offset;
    while (newOffset < text.length - 1) {
      final next = text.substring(newOffset);
      final match = skipNewline
          ? _whitespaceOrNewline.firstMatch(next)
          : _whitespace.firstMatch(next);
      if (match == null) {
        break;
      }
      newOffset += match.end;
    }
    return newOffset;
  }

  static void _processSoftBreak(
    final List<String> lines,
    final PageBreakType breakType,
    int maxLinesFromEndToBreakPage,
  ) {
    // Flutter handles page break on word automatically.
    if (breakType == PageBreakType.word) {
      return;
    }

    for (int i = lines.length - 1;
        i >= max(1, lines.length - maxLinesFromEndToBreakPage);
        i--) {
      final line = lines[i];
      final match = breakType.regex.allMatches(line).lastOrNull;
      if (match == null) {
        continue;
      }

      final cutLine = line.substring(0, match.end);
      lines[i] = cutLine;
      if (i < lines.length - 1) {
        lines.removeRange(i + 1, lines.length);
      }
      break;
    }

    return;
  }

  static int _processHardBreak(
    final List<String> lines,
    final Pattern hardPageBreak,
    int offset,
  ) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final match = hardPageBreak.allMatches(line).firstOrNull;
      if (match == null) {
        continue;
      }
      final cutLine = line.substring(0, match.start);
      lines[i] = cutLine;
      offset += (match.end - match.start);
      if (i < lines.length - 1) {
        lines.removeRange(i + 1, lines.length);
      }
      break;
    }
    return offset;
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
