import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:paginated_text/src/cap_style.dart';
import 'package:paginated_text/src/paginate_data.dart';
import 'extensions.dart';

import 'compute_cap_text_style.dart';
import 'page_break_type.dart';
import 'text_page.dart';

final _whitespace = RegExp(r'^(\s*\n|\s(?=\S))');

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
      : TextOnlyPage.blank();

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
    assert(data.dropCapLines >= 0 && data.dropCapLines <= 5,
        'dropCapLines must be 0-5');
    print('paginate');
    final List<TextPage> pages = [];
    double remainingHeight = layoutSize.height;
    final lineHeight = data.textStyle.height ?? 1.2;
    int offset = 0;
    final List<String> capLines = [];
    String? capChar;
    TextPainter? capPainter;
    TextPainter? capLinesPainter;
    String pageText = '';
    TextStyle? capTextStyle;

    if (data.dropCapLines > 0) {
      capChar = data.text[0];
      final effectiveCapStyle =
          data.capStyle ?? CapStyle.fromStyle(data.textStyle);
      capTextStyle = await computeCapTextStyle(
        capStyle: effectiveCapStyle,
        textStyle: data.textStyle,
        lineHeight: lineHeight,
        textScaler: data.textScaler,
        capLines: data.dropCapLines,
      );
      capPainter = TextPainter(
        text: TextSpan(text: capChar, style: capTextStyle),
        textDirection: data.textDirection,
        maxLines: 1,
        strutStyle: StrutStyle.fromTextStyle(capTextStyle),
        textScaler: data.textScaler,
      )..layout();

      final capLinesText = data.text.substring(1);
      capLinesPainter = TextPainter(
        text: TextSpan(text: capLinesText, style: data.textStyle),
        textDirection: data.textDirection,
        strutStyle: StrutStyle.fromTextStyle(data.textStyle),
        maxLines: data.dropCapLines,
        textScaler: data.textScaler,
      )..layout(maxWidth: layoutSize.width - capPainter.width);

      remainingHeight -= capLinesPainter.height;

      capLines.addAll(capLinesPainter
          .computeLineMetrics()
          .getLineTexts(capLinesPainter, capLinesText));

      offset = _processHardBreak(capLines, data.hardPageBreak, offset);

      pageText = capChar + capLines.join();
      offset += pageText.length;
    }

    final textFontSize = data.textStyle.fontSize ?? data.textScaler.scale(14.0);
    final linePixelHeight = lineHeight * textFontSize;
    final maxLinesPerPage = (layoutSize.height / linePixelHeight).ceil();

    while (offset < data.text.length - 1) {
      final start = offset;
      final remainingText = data.text.substring(offset);

      final textPainter = TextPainter(
        text: TextSpan(text: remainingText, style: data.textStyle),
        textDirection: data.textDirection,
        strutStyle: StrutStyle.fromTextStyle(data.textStyle),
        maxLines: maxLinesPerPage,
        textScaler: data.textScaler,
      )..layout(maxWidth: layoutSize.width);

      final lineMetrics = textPainter
          .computeLineMetrics()
          .takeWhile((line) => line.baseline < remainingHeight)
          .toList();

      final restLines = lineMetrics.getLineTexts(textPainter, remainingText);

      offset = _processHardBreak(restLines, data.hardPageBreak, offset);
      _processSoftBreak(
          restLines, data.breakType, data.maxLinesFromEndToBreakPage);

      final remainingPageText = restLines.join();
      offset += remainingPageText.length;
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
              start: 0,
              end: offset,
              capLines: capLines,
              capChar: capChar,
              restLines: restLines,
              text: pageText,
              endBreakType: data.breakType,
              capStyle: capTextStyle,
              capAlign: TextAlign.center,
              textAlign: TextAlign.start,
              textDirection: data.textDirection,
              textStyle: data.textStyle,
              textScaler: data.textScaler,
            )
          : TextOnlyPage(
              breakType: data.breakType,
              painter: textPainter,
              start: start,
              end: offset,
              lines: restLines,
              text: pageText,
            );

      pages.add(page);

      while (offset < data.text.length - 1) {
        final next = data.text.substring(offset);
        final match = _whitespace.firstMatch(next);
        if (match == null) {
          break;
        }
        offset += match.end;
      }
    }

    return Paginated._(
      text: data.text,
      textStyle: data.textStyle,
      capTextStyle: capTextStyle,
      layoutSize: layoutSize,
      pages: pages,
    );
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
