library paginated_text;

import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:paginated_text/src/extensions/line_metrics_extension.dart';
import 'package:paginated_text/src/models/models.dart';
import 'package:paginated_text/src/widgets/drop_cap_text.dart';

export 'package:paginated_text/src/models/models.dart';
export 'package:paginated_text/src/widgets/drop_cap_text.dart';

class FittedText {
  final int length;
  final double height;
  final List<String> lines;

  const FittedText({
    required this.length,
    required this.height,
    required this.lines,
  });

  static FittedText fit({
    required String text,
    required double width,
    required TextScaler textScaler,
    required TextDirection textDirection,
    required TextStyle style,
    required int maxLines,
  }) {
    assert(maxLines > 0, 'maxLines = $maxLines; must be > 0');

    final textSpan = TextSpan(
      text: text,
      style: style,
    );

    final strutStyle = StrutStyle.fromTextStyle(style);

    final textPainter = TextPainter(
      text: textSpan,
      textScaler: textScaler,
      textDirection: textDirection,
      strutStyle: strutStyle,
      maxLines: maxLines,
    )..layout(
        minWidth: width,
        maxWidth: width,
      );

    final List<LineMetrics> lineMetrics = textPainter.computeLineMetrics();
    final List<String> lines = lineMetrics.map((line) {
      final start = textPainter.getPositionForOffset(line.leftBaseline).offset;
      final end =
          1 + textPainter.getPositionForOffset(line.rightBaseline).offset;
      final lineText = text.substring(start, min(end, text.length));
      return lineText;
    }).toList();

    return FittedText(
      length: lines.join().length,
      height: lineMetrics.last.bottom,
      lines: lines,
    );
  }
}

class PaginatedText extends StatefulWidget {
  const PaginatedText(
    this.controller, {
    super.key,
  });

  final PaginatedController controller;

  @override
  State<PaginatedText> createState() => _PaginatedTextState();
}

class _PaginatedTextState extends State<PaginatedText> {
  late final PaginatedController controller = widget.controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        return LayoutBuilder(builder: (context, constraints) {
          final currentPage = controller.currentPage;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            controller.updateLayoutSize(constraints.biggest);
          });
          return DropCapText(
            key: ValueKey(currentPage),
            currentPage.text,
            parseInlineMarkdown: true,
            style: controller.data.style,
            dropCapStyle: controller.data.dropCapStyle,
            dropCapChars: currentPage.pageIndex == 0 ? 1 : 0,
            capLines: controller.data.dropCapLines,
          );
        });
      },
    );
  }
}

class PaginatedController with ChangeNotifier {
  PaginateData get data => _data;
  PaginateData _data;
  Size _layoutSize;

  PageInfo get currentPage =>
      pages.isNotEmpty ? pages[_pageIndex] : PageInfo.empty;
  late final pages = UnmodifiableListView(_pages);
  int get pageIndex => _pageIndex;
  int get maxLinesPerPage => _maxLinesPerPage;
  double get lineHeight => _lineHeight;

  final List<PageInfo> _pages = [];
  int _pageIndex = 0;
  int _maxLinesPerPage = 0;
  double _lineHeight = 0.0;

  PaginatedController(this._data) : _layoutSize = Size.zero;

  void updateLayoutSize(Size layoutSize) {
    final dx =
        (layoutSize.width - _layoutSize.width).abs() > _data.sizeTolerance;
    final dy = dx ||
        (layoutSize.height - _layoutSize.height).abs() > _data.sizeTolerance;
    if (dx || dy) {
      update(_data, layoutSize);
    }
  }

  void next() {
    if (_pageIndex == _pages.length - 1) {
      return;
    }
    _pageIndex++;
    notifyListeners();
  }

  void previous() {
    if (_pageIndex == 0) {
      return;
    }
    _pageIndex--;
    notifyListeners();
  }

  void setPageIndex(int pageIndex) {
    if (pageIndex < 0 || pageIndex > _pages.length - 1) {
      throw RangeError.range(pageIndex, 0, _pages.length - 1);
    }
    _pageIndex = pageIndex;
    notifyListeners();
  }

  void update(PaginateData data, Size layoutSize) {
    if (data == _data && layoutSize == _layoutSize) {
      return;
    }

    _data = data;
    _layoutSize = layoutSize;

    _pages.clear();

    if (layoutSize == Size.zero || data.text.isEmpty) {
      _pages.add(PageInfo.empty);
      notifyListeners();
      return;
    }

    final lineHeight =
        (data.style.height ?? 1.0) * (data.style.fontSize ?? 14.0);
    _lineHeight = lineHeight;
    final maxLinesPerPage =
        max(data.dropCapLines, (layoutSize.height / lineHeight).floor());
    _maxLinesPerPage = maxLinesPerPage;

    int pageIndex = 0;
    int restOfPageStart = 0;
    int remainingLinesOnPage = maxLinesPerPage;

    FittedText? fittedCapLines;

    if (data.dropCapLines > 0) {
      final capStyle = data.dropCapStyle;
      final capSpan = TextSpan(
        text: data.text.characters.first,
        style: capStyle,
      );
      final capPainter = TextPainter(
        text: capSpan,
        textDirection: data.textDirection,
      )..layout();

      fittedCapLines = FittedText.fit(
        text: data.text.substring(1),
        width: layoutSize.width - capPainter.width,
        style: data.style,
        textScaler: data.textScaler,
        textDirection: data.textDirection,
        maxLines: min(maxLinesPerPage, data.dropCapLines),
      );
      final text = data.text.characters.first + fittedCapLines.lines.join();
      final lines = fittedCapLines.lines.length;
      restOfPageStart = fittedCapLines.length + 1;
      remainingLinesOnPage -= data.dropCapLines;

      // If all our text fits in the drop cap lines:
      if (restOfPageStart >= data.text.length || remainingLinesOnPage < 1) {
        final pageInfo = PageInfo(
          pageIndex: pageIndex,
          text: text,
          lines: lines,
        );
        _pages.add(pageInfo);
        _pageIndex = min(_pageIndex, _pages.length - 1);
        notifyListeners();
        return;
      }
    }

    while (restOfPageStart < data.text.length) {
      final fittedLines = FittedText.fit(
        text: data.text.substring(restOfPageStart),
        width: layoutSize.width,
        style: data.style,
        textScaler: data.textScaler,
        textDirection: data.textDirection,
        maxLines: remainingLinesOnPage,
      );
      final dropCapLines = pageIndex == 0 ? fittedCapLines?.lines ?? [] : [];
      final firstChar = pageIndex == 0 ? data.text.characters.first : '';
      final lines = dropCapLines + fittedLines.lines;
      final text = firstChar + lines.join();
      final numLines = lines.length;
      final pageInfo = PageInfo(
        pageIndex: pageIndex,
        text: text,
        lines: numLines,
      );
      _pages.add(pageInfo);
      restOfPageStart += fittedLines.length;
      remainingLinesOnPage = maxLinesPerPage;
      pageIndex++;
    }

    _pageIndex = min(pageIndex, _pageIndex);

    notifyListeners();
  }
}
