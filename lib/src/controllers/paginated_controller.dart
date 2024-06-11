import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:paginated_text/src/models/models.dart';
import 'package:paginated_text/src/utils/fitted_text.dart';

/// The controller with `ChangeNotifier` that computes the text pages from `PaginateData`.
class PaginatedController with ChangeNotifier {
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
  int _maxLinesPerPage = 0;
  double _lineHeight = 0.0;

  PaginatedController(this._data) : _layoutSize = Size.zero;

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

  void _paginate(PaginateData data, Size layoutSize) {
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
    int remainingLinesOnPage = maxLinesPerPage;

    FittedText? fittedCapLines;
    int textPosition = 0;

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
      textPosition = text.length;
      remainingLinesOnPage -= data.dropCapLines;

      // If all our text fits in the drop cap lines:
      if (textPosition >= data.text.length || remainingLinesOnPage < 1) {
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

    while (textPosition < data.text.length) {
      final fittedLines = FittedText.fit(
        text: data.text.substring(textPosition),
        width: layoutSize.width,
        style: data.style,
        textScaler: data.textScaler,
        textDirection: data.textDirection,
        maxLines: remainingLinesOnPage,
      );
      if (pageIndex == 0) {
        textPosition = 0;
      }
      final List<String> dropCapLines =
          pageIndex == 0 ? fittedCapLines?.lines ?? [] : [];
      final firstChar = pageIndex == 0 ? data.text.characters.first : '';
      final List<String> lines = dropCapLines + fittedLines.lines;
      final minBreakLine = lines.length - min(lines.length, data.breakLines);
      final pageBreakIndex = PageBreak.values.indexOf(data.pageBreak);

      String text = firstChar + lines.join();
      int numLines = lines.length;

      pageBreakLoop:
      for (int pb = pageBreakIndex; pb > 0; pb--) {
        final pageBreak = PageBreak.values[pb].regex;
        for (int i = lines.length - 1; i >= minBreakLine; i--) {
          final match = pageBreak.allMatches(lines[i]).lastOrNull;
          if (match != null) {
            text = firstChar +
                lines.sublist(0, i).join() +
                lines[i].substring(0, match.end);
            numLines = i + 1;
            break pageBreakLoop;
          }
        }
      }

      final pageInfo = PageInfo(
        pageIndex: pageIndex,
        text: text,
        lines: numLines,
      );
      _pages.add(pageInfo);
      textPosition += text.length;
      remainingLinesOnPage = maxLinesPerPage;
      pageIndex++;
    }

    _pageIndex = min(pageIndex, _pageIndex);

    notifyListeners();
  }
}
