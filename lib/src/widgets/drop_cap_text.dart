import 'dart:collection';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:paginated_text/src/utils/get_cap_font_size.dart';

import '../constants.dart';

// Flutter Text Rendering
// https://flutter.megathink.com/text/text-rendering

enum DropCapMode {
  /// default
  inside,
  aside,
}

enum DropCapPosition {
  start,
  end,
}

class DropCap extends StatelessWidget {
  final Widget child;
  final double width, height;

  const DropCap({
    super.key,
    required this.child,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, height: height, child: child);
  }
}

// Hash key for the `letterHeightRatioCache`
class CapFontData {
  final String? fontFamily;
  final FontWeight? fontWeight;
  final FontStyle? fontStyle;

  const CapFontData(this.fontFamily, this.fontWeight, this.fontStyle);

  factory CapFontData.fromStyle(TextStyle style) =>
      CapFontData(style.fontFamily, style.fontWeight, style.fontStyle);

  @override
  int get hashCode => Object.hash(fontFamily, fontWeight, fontStyle);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CapFontData &&
          fontFamily == other.fontFamily &&
          fontWeight == other.fontWeight &&
          fontStyle == other.fontStyle);

  @override
  String toString() =>
      '$runtimeType(fontFamily: $fontFamily, fontWeight: $fontWeight, fontStyle: $fontStyle)';
}

const bool debug = false;

// Cache letter height to font size ratios for each font family.
final letterHeightRatioCache = HashMap<CapFontData, double>();

// Font size used to compute the letter height ratio.
const double letterHeightCalcFontSize = 3600.0;

class DropCapText extends StatefulWidget {
  final String data;
  final DropCapMode mode;
  final TextScaler textScaler;
  final int capLines;
  final TextStyle? style;
  final TextStyle? dropCapStyle;
  final TextAlign textAlign;
  final DropCap? dropCap;
  final EdgeInsets dropCapPadding;
  final Offset indentation;
  // final bool forceNoDescent;
  final bool parseInlineMarkdown;
  final TextDirection textDirection;
  final DropCapPosition? dropCapPosition;
  final int? maxLines;
  final TextOverflow overflow;

  const DropCapText(
    this.data, {
    super.key,
    required this.capLines,
    this.mode = DropCapMode.inside,
    this.textScaler = TextScaler.noScaling,
    this.style,
    this.dropCapStyle,
    this.textAlign = TextAlign.start,
    this.dropCap,
    this.dropCapPadding = EdgeInsets.zero,
    this.indentation = Offset.zero,
    this.parseInlineMarkdown = false,
    this.textDirection = TextDirection.ltr,
    this.overflow = TextOverflow.clip,
    this.maxLines,
    this.dropCapPosition,
  });

  @override
  State<DropCapText> createState() => _DropCapTextState();
}

class _DropCapTextState extends State<DropCapText> {
  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle =
        DefaultTextStyle.of(context).style.merge(widget.style);
    final TextStyle dropCapStyle = DefaultTextStyle.of(context)
        .style
        .merge(widget.dropCapStyle ?? widget.style);

    if (widget.data == '') return Text(widget.data, style: textStyle);

    final capLines = widget.capLines;
    final int dropCapChars =
        widget.dropCap == null && widget.capLines > 0 ? 1 : 0;

    MarkdownParser? mdData =
        widget.parseInlineMarkdown ? MarkdownParser(widget.data) : null;

    final String dropCapStr =
        (mdData?.plainText ?? widget.data).substring(0, dropCapChars);

    final hasDropCapLines = capLines > 0 && dropCapStr.isNotEmpty;

    final fontSize = textStyle.fontSize ?? 14.0;
    final height = textStyle.height ?? 1.0;

    final capFontFamily = dropCapStyle.fontFamily ?? textStyle.fontFamily;
    final capFontWeight = dropCapStyle.fontWeight ?? textStyle.fontWeight;
    final capFontStyle = dropCapStyle.fontStyle ?? textStyle.fontStyle;

    final [textLetterHeightRatio, capLetterHeightRatio] =
        _getOrComputeLetterHeightRatios([
      CapFontData.fromStyle(textStyle),
      CapFontData(capFontFamily, capFontWeight, capFontStyle),
    ]);

    final wantedCapFontSize = getCapFontSize(
      textFontSize: fontSize,
      lineHeight: height,
      capLines: capLines,
      textLetterHeightRatio: textLetterHeightRatio,
      capLetterHeightRatio: capLetterHeightRatio,
    );

    final TextStyle capStyle = dropCapStyle.copyWith(
      fontSize: wantedCapFontSize,
      height: 1.0,
    );

    double capWidth = 0;
    double capHeight = 0;
    TextPainter? capPainter;
    double capBaseline = 0;
    bool didExceedCapLines = false;

    // compute drop cap padding
    capWidth += widget.dropCapPadding.left + widget.dropCapPadding.right;
    capHeight += widget.dropCapPadding.top + widget.dropCapPadding.bottom;

    // custom DropCap
    if (widget.dropCap != null) {
      capWidth += widget.dropCap!.width;
      capHeight += widget.dropCap!.height;
    }

    // auto drop cap
    else if (hasDropCapLines) {
      capPainter = TextPainter(
        text: TextSpan(
          text: dropCapStr,
          style: capStyle,
        ),
        maxLines: 1,
        textScaler: widget.textScaler,
        textDirection: widget.textDirection,
      )..layout();
      capWidth += capPainter.width;
      capHeight += capPainter.height;
      final List<LineMetrics> lm = capPainter.computeLineMetrics();
      capBaseline = lm[0].baseline;
      capHeight -=
          lm.isNotEmpty ? lm[0].descent * 0.5 : capPainter.height * 0.2;
    }

    MarkdownParser? mdRest =
        widget.parseInlineMarkdown ? mdData!.subchars(dropCapChars) : null;
    String remainingText = widget.data.substring(dropCapChars);

    TextSpan textSpan = TextSpan(
      text: widget.parseInlineMarkdown ? null : remainingText,
      children: widget.parseInlineMarkdown ? mdRest!.toTextSpanList() : null,
      style: textStyle,
    );

    TextPainter textPainter = TextPainter(
      textDirection: widget.textDirection,
      text: textSpan,
      textAlign: widget.textAlign,
      textScaler: widget.textScaler,
    );
    double lineHeight = textPainter.preferredLineHeight;

    // BUILDER
    return Semantics(
      label: widget.data,
      child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
        final double boundsWidth = max(1.0, constraints.maxWidth - capWidth);

        int capLinesEndIndex = 0;
        double textBaseline = capBaseline;

        if (hasDropCapLines) {
          textPainter
            ..maxLines = capLines
            ..layout(maxWidth: boundsWidth);
          final textLines = textPainter.computeLineMetrics();
          if (debug) {
            for (final (index, line) in textLines.indexed) {
              final start = textPainter
                  .getPositionForOffset(Offset(0, line.baseline))
                  .offset;
              final end = textPainter
                  .getPositionForOffset(Offset(line.width, line.baseline))
                  .offset;

              debugPrint('line $index: ${remainingText.substring(start, end)}');
            }
          }
          didExceedCapLines = textLines.length >= capLines;
          if (didExceedCapLines) {
            final lastCapLine = textLines[capLines - 1];
            textBaseline = lastCapLine.baseline;
            capLinesEndIndex = 1 +
                textPainter
                    .getPositionForOffset(
                        Offset(lastCapLine.width, textBaseline))
                    .offset;
          }
        }

        // DROP CAP MODE - ASIDE
        if (widget.mode == DropCapMode.aside) {
          capLinesEndIndex = widget.data.length;
        }

        final maxLines = (constraints.maxHeight / lineHeight).floor();
        final maxCapLines = capLines.clamp(0, maxLines);
        final maxTextLines = max(0, maxLines - maxCapLines);

        return Container(
          decoration: debug
              ? BoxDecoration(border: Border.all(color: Colors.red, width: 2))
              : null,
          child: OverflowBox(
            alignment: Alignment.topLeft,
            maxWidth: constraints.maxWidth,
            maxHeight: constraints.maxHeight,
            child: Column(
              children: <Widget>[
                if (hasDropCapLines)
                  Container(
                    decoration: debug
                        ? BoxDecoration(
                            border: Border.all(width: 2, color: Colors.pink))
                        : null,
                    child: Row(
                      // textDirection: widget.dropCapPosition == null ||
                      //         widget.dropCapPosition == DropCapPosition.start
                      //     ? widget.textDirection
                      //     : (widget.textDirection == TextDirection.ltr
                      //         ? TextDirection.rtl
                      //         : TextDirection.ltr),
                      // crossAxisAlignment: CrossAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      // textBaseline: TextBaseline.alphabetic,
                      children: <Widget>[
                        widget.dropCap ??
                            SizedOverflowBox(
                              // alignment: Alignment.bottomLeft,
                              alignment: Alignment.topLeft,
                              size: Size(capWidth, 0),
                              child: Container(
                                clipBehavior: Clip.none,
                                width: capWidth,
                                height:
                                    capHeight + (textBaseline - capBaseline),
                                transform: Transform.translate(
                                  offset: Offset(0, textBaseline - capBaseline),
                                ).transform,
                                decoration: debug
                                    ? BoxDecoration(
                                        border: Border.all(
                                          color: Colors.yellowAccent,
                                          width: 2,
                                        ),
                                      )
                                    : null,
                                alignment: Alignment.topLeft,

                                // Drop Cap Cap Itself
                                child: Text.rich(
                                  TextSpan(
                                    text: dropCapStr,
                                    style: capStyle,
                                  ),
                                  overflow: TextOverflow.visible,
                                  textDirection: widget.textDirection,
                                  textAlign: widget.textAlign,
                                  maxLines: 1,
                                  textScaler: widget.textScaler,
                                ),
                              ),
                            ),
                        Container(
                          padding: EdgeInsets.only(top: widget.indentation.dy),
                          width: boundsWidth,
                          decoration: debug
                              ? BoxDecoration(
                                  border: Border.all(
                                    color: Colors.green,
                                    width: 2,
                                  ),
                                )
                              : null,
                          // height: widget.mode != DropCapMode.aside
                          //     ? (lineHeight *
                          //             min(widget.maxLines ?? capLines,
                          //                 capLines)) +
                          //         widget.indentation.dy
                          //     : null,

                          // Drop Cap Lines
                          child: Text.rich(
                            textSpan,
                            overflow: (widget.maxLines == null ||
                                    (widget.maxLines! > capLines &&
                                        widget.overflow == TextOverflow.fade))
                                ? TextOverflow.clip
                                : widget.overflow,
                            maxLines: maxCapLines,
                            textDirection: widget.textDirection,
                            textAlign: widget.textAlign,
                            textScaler: widget.textScaler,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (!hasDropCapLines || didExceedCapLines)
                  Container(
                    decoration: debug
                        ? BoxDecoration(
                            border: Border.all(
                              color: Colors.purple,
                              width: 2,
                            ),
                          )
                        : null,
                    child: Padding(
                      padding: EdgeInsets.only(left: widget.indentation.dx),

                      // Rest of Text
                      child: Text.rich(
                        TextSpan(
                          text: widget.parseInlineMarkdown
                              ? null
                              : remainingText.substring(
                                  min(capLinesEndIndex, remainingText.length)),
                          children: widget.parseInlineMarkdown
                              ? mdRest!
                                  .subchars(capLinesEndIndex)
                                  .toTextSpanList()
                              : null,
                          style: textStyle,
                        ),
                        overflow: widget.overflow,
                        maxLines: maxTextLines,
                        textAlign: widget.textAlign,
                        textDirection: widget.textDirection,
                        textScaler: widget.textScaler,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Future<double> _computeLetterHeightRatio(CapFontData fontData) async {
    if (letterHeightRatioCache.containsKey(fontData)) {
      return letterHeightRatioCache[fontData]!;
    }

    final painter = TextPainter(
      text: TextSpan(
        text: 'Z',
        style: TextStyle(
          fontFamily: fontData.fontFamily,
          fontWeight: fontData.fontWeight,
          fontStyle: fontData.fontStyle,
          fontSize: letterHeightCalcFontSize,
        ),
      ),
      textScaler: TextScaler.noScaling,
      textDirection: widget.textDirection,
    )..layout();
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    painter.paint(canvas, Offset.zero);
    final picture = recorder.endRecording();
    final image =
        await picture.toImage(painter.width.ceil(), painter.height.ceil());
    final bytes = await image.toByteData(format: ImageByteFormat.rawRgba);
    if (bytes == null) {
      letterHeightRatioCache[fontData] = defaultLetterHeightRatio;
      return defaultLetterHeightRatio;
    }
    final x = (image.width / 2).round();
    final line = List<bool>.generate(image.height, (y) {
      // https://github.com/marcglasberg/image_pixels/blob/master/lib/src/image_pixels.dart#L194
      final offset = 4 * (x + (y * image.width));
      // https://github.com/marcglasberg/image_pixels/blob/master/lib/src/image_pixels.dart#214
      final pixel = bytes.getUint32(offset);
      return pixel > 0;
    });
    final top = line.indexWhere((y) => y);
    final baseline = line.lastIndexWhere((y) => y);
    final letterHeight = (baseline - top).toDouble();

    final ratio = letterHeight / letterHeightCalcFontSize;
    letterHeightRatioCache[fontData] = ratio;
    return ratio;
  }

  List<double> _getOrComputeLetterHeightRatios(List<CapFontData> fontDatas) {
    final allHits =
        fontDatas.every((key) => letterHeightRatioCache.containsKey(key));

    if (allHits) {
      return fontDatas.map((d) => letterHeightRatioCache[d]!).toList();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.wait(fontDatas.map((d) => _computeLetterHeightRatio(d)));
      setState(() {});
    });

    return fontDatas.map((d) => defaultLetterHeightRatio).toList();
  }
}

class MarkdownParser {
  final String data;
  late List<MarkdownSpan> spans;
  String plainText = '';

  List<TextSpan> toTextSpanList() {
    return spans.map((s) => s.toTextSpan()).toList();
  }

  MarkdownParser subchars(int startIndex, [int? endIndex]) {
    final List<MarkdownSpan> subspans = [];
    int skip = startIndex;
    for (int s = 0; s < spans.length; s++) {
      MarkdownSpan span = spans[s];
      if (skip <= 0) {
        subspans.add(span);
      } else if (span.text.length < skip) {
        skip -= span.text.length;
      } else {
        subspans.add(
          MarkdownSpan(
            style: span.style,
            markups: span.markups,
            text: span.text.substring(skip, span.text.length),
          ),
        );
        skip = 0;
      }
    }

    return MarkdownParser(
      subspans
          .asMap()
          .map((int index, MarkdownSpan span) {
            String markup = index > 0
                ? (span.markups.isNotEmpty ? span.markups[0].code : '')
                : span.markups.map((m) => m.isActive ? m.code : '').join();
            return MapEntry(index, '$markup${span.text}');
          })
          .values
          .toList()
          .join(),
    );
  }

  MarkdownParser(this.data) {
    plainText = '';
    spans = [MarkdownSpan(text: '', markups: [], style: const TextStyle())];

    bool bold = false;
    bool italic = false;
    bool underline = false;

    const String markupBold = '**';
    const String markupItalic = '_';
    const String markupUnderline = '++';

    addSpan(String markup, bool isOpening) {
      final List<Markup> markups = [Markup(markup, isOpening)];

      if (bold && markup != markupBold) {
        markups.add(Markup(markupBold, true));
      }
      if (italic && markup != markupItalic) {
        markups.add(Markup(markupItalic, true));
      }
      if (underline && markup != markupUnderline) {
        markups.add(Markup(markupUnderline, true));
      }

      spans.add(
        MarkdownSpan(
          text: '',
          markups: markups,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : null,
            fontStyle: italic ? FontStyle.italic : null,
            decoration: underline ? TextDecoration.underline : null,
          ),
        ),
      );
    }

    bool checkMarkup(int i, String markup) {
      return data.substring(i, min(i + markup.length, data.length)) == markup;
    }

    for (int c = 0; c < data.length; c++) {
      if (checkMarkup(c, markupBold)) {
        bold = !bold;
        addSpan(markupBold, bold);
        c += markupBold.length - 1;
      } else if (checkMarkup(c, markupItalic)) {
        italic = !italic;
        addSpan(markupItalic, italic);
        c += markupItalic.length - 1;
      } else if (checkMarkup(c, markupUnderline)) {
        underline = !underline;
        addSpan(markupUnderline, underline);
        c += markupUnderline.length - 1;
      } else {
        spans[spans.length - 1].text += data[c];
        plainText += data[c];
      }
    }
  }
}

class MarkdownSpan {
  final TextStyle style;
  final List<Markup> markups;
  String text;

  TextSpan toTextSpan() => TextSpan(text: text, style: style);

  MarkdownSpan({
    required this.text,
    required this.style,
    required this.markups,
  });
}

class Markup {
  final String code;
  final bool isActive;

  Markup(this.code, this.isActive);
}
