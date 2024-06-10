class PageInfo {
  final int pageIndex;
  final String text;
  final int lines;

  const PageInfo({
    required this.pageIndex,
    required this.text,
    required this.lines,
  });

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
}
