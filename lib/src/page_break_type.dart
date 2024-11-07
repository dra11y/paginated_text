/// Determines how the page break should occur during pagination.
enum PageBreakType {
  /// Break pages on the last visible word of the page.
  word,

  /// Attempt to break pages at a period, comma, semicolon, or em dash (-- / —).
  fragment,

  /// Attempt to break pages at the end of a sentence.
  sentence,

  /// Attempt to break at paragraphs (two consecutive newlines).
  paragraph;

  RegExp get regex => _regexMap[this]!;

  static final Map<PageBreakType, RegExp> _regexMap = {
    PageBreakType.fragment: RegExp(r'([.,;:]\s+|(—|–|--)\s*)'),
    PageBreakType.sentence: RegExp(r'\.\S*[^\S]*'),
    PageBreakType.paragraph: RegExp(r'[\r\n\s*]{2,}'),
    PageBreakType.word: RegExp(r'\s+'),
  };
}
