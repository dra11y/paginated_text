import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:paginated_text/src/constants.dart';
import 'package:paginated_text/src/models/models.dart';
import 'package:paginated_text/src/utils/fitted_text.dart';

import '../utils/get_cap_font_size.dart';

typedef OnPaginateCallback = void Function(PaginatedController);

final _reFirstSpacesInLine = RegExp(r'^\s+');

class NextLinesData {
  final List<String> lines;
  final int nextPosition;
  final bool didExceedMaxLines;

  NextLinesData({
    required this.lines,
    required this.nextPosition,
    required this.didExceedMaxLines,
  });

  @override
  String toString() => [
        '$runtimeType(',
        '    lines: $lines,',
        '    nextPosition: $nextPosition,',
        '    didExceedMaxLines: $didExceedMaxLines,',
        ')',
      ].join('\n');
}

/// The controller with `ChangeNotifier` that computes the text pages from `PaginateData`.
class PaginatedController with ChangeNotifier {
  PaginatedController(
    this._data, {
    this.onPaginate,
    int defaultMaxLinesPerPage = 10,
  })  : _layoutSize = Size.zero,
        _maxLinesPerPage = defaultMaxLinesPerPage;

  /// The data this controller was instantiated with.
  PaginateData get paginateData => _data;

  /// Whether the current page is the first page.
  bool get isFirst => pageIndex == 0;

  /// Whether the current page is the last page.
  bool get isLast => pageIndex == pages.length - 1;

  /// The current page model.
  PageInfo get currentPage =>
      pages.isNotEmpty ? pages[_pageIndex] : PageInfo.empty;

  /// An unmodifiable list of the current paginated page models.
  late final pages = UnmodifiableListView(_pages);

  /// The index of the current page.
  int get pageIndex => _pageIndex;

  /// The index of the page previously viewed.
  int get previousPageIndex => _previousPageIndex;

  /// The 1-based number of the current page (pageIndex + 1).
  int get pageNumber => _pageIndex + 1;

  /// The number or count of pages after pagination.
  int get numPages => pages.length;

  /// The size of the layout used for the current pagination.
  Size get layoutSize => _layoutSize;

  /// The maximum number of lines that can be shown on the page,
  /// given the `layoutSize`.
  int get maxLinesPerPage => _maxLinesPerPage;

  /// The height of a single line given the configured `PaginateData.style`.
  double get lineHeight => _lineHeight;

  PaginateData _data;
  Size _layoutSize;
  final List<PageInfo> _pages = [];
  int _pageIndex = 0;
  int _previousPageIndex = 0;
  int _maxLinesPerPage;
  double _lineHeight = 0.0;

  OnPaginateCallback? onPaginate;

  /// Tells the controller to update its `layoutSize`. Causes repagination if needed.
  void updateLayoutSize(Size layoutSize) {
    final dx =
        (layoutSize.width - _layoutSize.width).abs() > _data.resizeTolerance;
    final dy = dx ||
        (layoutSize.height - _layoutSize.height).abs() > _data.resizeTolerance;
    if (dx || dy) {
      update(_data, layoutSize);
    }
  }

  /// Go to the next page. Do nothing if on the last page.
  void next() {
    if (_pageIndex == _pages.length - 1) {
      return;
    }
    _previousPageIndex = _pageIndex;
    _pageIndex++;
    notifyListeners();
  }

  /// Go to the previous page. Do nothing if on the first page.
  void previous() {
    if (_pageIndex == 0) {
      return;
    }
    _previousPageIndex = _pageIndex;
    _pageIndex--;
    notifyListeners();
  }

  /// Sets the page explicitly to a given index. Throws a `RangeError` if out of range.
  void setPageIndex(int pageIndex) {
    if (pageIndex < 0 || pageIndex > _pages.length - 1) {
      throw RangeError.range(pageIndex, 0, _pages.length - 1);
    }
    _previousPageIndex = _pageIndex;
    _pageIndex = pageIndex;
    notifyListeners();
  }

  /// Update this controller instance with given `data` and `layoutSize`.
  void update(PaginateData data, Size layoutSize) {
    if (data == _data && layoutSize == _layoutSize) {
      return;
    }

    _paginate(data, layoutSize);
  }

  NextLinesData _getNextLines({
    required bool autoPageBreak,
    required int textPosition,
    required double width,
    required int maxLines,
  }) {
    final String currentText = _data.text.substring(textPosition);
    final fittedText = FittedText.fit(
      text: currentText,
      width: width,
      style: _data.style,
      textScaler: _data.textScaler,
      textDirection: _data.textDirection,
      maxLines: maxLines,
    );

    final fittedString = fittedText.lines.join();

    final hardPageBreak = _data.hardPageBreak;
    final firstHardPageBreak =
        hardPageBreak.allMatches(fittedString).firstOrNull;

    if (firstHardPageBreak != null) {
      final lineIndex =
          fittedText.lines.indexWhere((line) => line.contains(hardPageBreak));
      final List<String> lines = fittedText.lines
          .sublist(0, lineIndex)
          // .skipWhile((line) => line.trim().isEmpty)
          .mapIndexed((index, line) => lineIndex == index
              ? line.substring(0, line.indexOf(hardPageBreak))
              : line)
          .toList();

      return NextLinesData(
        lines: lines,
        // nextPosition: textPosition + firstHardPageBreak.end,
        // was this causing cutoff?
        nextPosition: textPosition + firstHardPageBreak.end + 1,
        didExceedMaxLines: fittedText.didExceedMaxLines,
      );
    }

    final List<String> lines = fittedText.lines;

    if (!autoPageBreak ||
        !fittedText.didExceedMaxLines ||
        _data.pageBreakType == PageBreakType.word) {
      return NextLinesData(
        lines: lines,
        nextPosition: textPosition + fittedString.length,
        didExceedMaxLines: fittedText.didExceedMaxLines,
      );
    }

    final pageBreakIndex = PageBreakType.values.indexOf(_data.pageBreakType);
    final minBreakLine = lines.length - min(lines.length, _data.breakLines);

    int nextPosition = textPosition + fittedString.length;

    if (fittedText.didExceedMaxLines) {
      pageBreakLoop:
      for (int pb = pageBreakIndex; pb > 0; pb--) {
        final pageBreak = PageBreakType.values[pb].regex;
        for (int i = lines.length - 1; i >= minBreakLine; i--) {
          final match = pageBreak.allMatches(lines[i]).lastOrNull;
          if (match != null) {
            // extraSpacesToSkipOnNextPage should initially be 0 to avoid cutting off the first letter on next page.
            int extraSpacesToSkipOnNextPage = 0;
            if (match.end < lines[i].length) {
              final line = lines[i].substring(0, match.end);
              final firstSpacesOnNextPage = _reFirstSpacesInLine
                  .stringMatch(lines[i].substring(match.end));
              if (firstSpacesOnNextPage != null) {
                extraSpacesToSkipOnNextPage = firstSpacesOnNextPage.length;
              }
              lines[i] = line;
            }
            if (i < lines.length - 1) {
              lines.removeRange(i + 1, lines.length);
            }
            nextPosition = textPosition +
                lines.join().length +
                extraSpacesToSkipOnNextPage;
            break pageBreakLoop;
          }
        }
      }
    }

    return NextLinesData(
      lines: lines,
      nextPosition: nextPosition,
      didExceedMaxLines: fittedText.didExceedMaxLines,
    );
  }

  void _paginate(PaginateData data, Size layoutSize) {
    _data = data;
    _layoutSize = layoutSize;
    _pages.clear();

    if (layoutSize == Size.zero || data.text.isEmpty) {
      _pages.add(PageInfo.empty);
      _notifyPaginate();
      return;
    }
    final lineHeight = data.textScaler.scale(data.style.fontSize ?? 14.0) *
        (data.style.height ?? 1.0);
    _lineHeight = lineHeight;
    final maxLinesPerPage =
        max(data.dropCapLines, (layoutSize.height / lineHeight).floor());
    _maxLinesPerPage = maxLinesPerPage;

    int pageIndex = 0;
    int textPosition = 0;

    while (textPosition < data.text.length) {
      String capChars = '';
      List<String> dropCapLines = [];
      bool didExceedDropCapLines = false;

      // compute drop cap lines
      if (textPosition == 0 && data.dropCapLines > 0) {
        capChars = data.text.substring(0, 1);
        textPosition += capChars.length;

        final wantedCapFontSize = getCapFontSize(
          textFontSize: data.style.fontSize ?? 14,
          lineHeight: data.style.height ?? 1.0,
          capLines: data.dropCapLines,
          textLetterHeightRatio: defaultLetterHeightRatio,
          capLetterHeightRatio: defaultLetterHeightRatio,
        );
        final capStyle = (data.dropCapStyle ?? data.style).copyWith(
          fontSize: wantedCapFontSize,
        );
        final capSpan = TextSpan(
          text: capChars,
          style: capStyle,
        );
        final capPainter = TextPainter(
          text: capSpan,
          textScaler: data.textScaler,
          textDirection: data.textDirection,
        )..layout();
        final nextLinesData = _getNextLines(
          autoPageBreak: false,
          textPosition: textPosition,
          width: layoutSize.width -
              capPainter.width -
              data.dropCapPadding.horizontal,
          maxLines: min(maxLinesPerPage, data.dropCapLines),
        );
        dropCapLines = nextLinesData.lines;
        textPosition = nextLinesData.nextPosition;
        didExceedDropCapLines = nextLinesData.didExceedMaxLines;

        // If our text did not exceed the drop cap lines area, break:
        if (!didExceedDropCapLines) {
          final pageInfo = PageInfo(
            pageIndex: pageIndex,
            text: capChars + dropCapLines.join(),
            lines: dropCapLines.length,
          );
          _pages.add(pageInfo);
          pageIndex++;
          break;
        }
      }

      List<String> nextLines = [];

      final remainingLinesOnPage = maxLinesPerPage - dropCapLines.length;
      final nextLinesData = _getNextLines(
        autoPageBreak: true,
        textPosition: textPosition,
        width: layoutSize.width,
        maxLines: remainingLinesOnPage,
      );

      nextLines = nextLinesData.lines;
      textPosition = nextLinesData.nextPosition;

      final text = capChars + dropCapLines.join() + nextLines.join();
      final lines = dropCapLines.length + nextLines.length;

      final pageInfo = PageInfo(
        pageIndex: pageIndex,
        text: text,
        lines: lines,
      );
      _pages.add(pageInfo);
      pageIndex++;
    }

    _pageIndex = min(pageIndex, _pageIndex);
    _notifyPaginate();
  }

  void _notifyPaginate() {
    onPaginate?.call(this);
    notifyListeners();
  }
}
