/// Model that provides the text, page index, and number of lines of a given page.
class PageInfo {
  /// The index of the page after pagination.
  final int pageIndex;

  /// The actual text of this page.
  final String text;

  /// The number of lines on this page.
  final int lines;

  const PageInfo({
    required this.pageIndex,
    required this.text,
    required this.lines,
  });

  /// Construct an empty page model.
  static get empty => const PageInfo(pageIndex: 0, text: '', lines: 0);

  @override
  int get hashCode => Object.hash(pageIndex, text, lines);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PageInfo &&
          pageIndex == other.pageIndex &&
          text == other.text &&
          lines == other.lines);

  @override
  String toString() =>
      'PageInfo(pageIndex: $pageIndex, text.length: ${text.length}, lines: $lines)';
}
