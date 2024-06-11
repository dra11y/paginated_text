# paginated_text

A Flutter package that provides a paginated text view with optional auto-sized initial drop cap.

![Animated GIF screen demo of paginated_text](https://raw.githubusercontent.com/dra11y/paginated_text/main/paginated_text_demo.gif)

## WIP - Work in Progress

### The API is subject to change in future versions at any time.

## Features

- Text is paginated automatically to fit in the widget's layout size;
- Use any (or no) animation and controls you want; this package provides the controller and a widget with a builder, but you can also make your own custom widget;
- The first letter can be a drop cap that is automatically positioned and sized:
    - the actual letter height(s) (using the letter 'Z') of the cap and text fonts is/are computed and cached:
        - Flutter currently provides no internal means to get the actual letter height of a font, therefore it must be painted, converted to an image, and inspected for the top/bottom pixels of the 'Z';
        - The result is cached (once each run for each font family, weight, and style) as a ratio and used to compute the font size from the desired letter height;
        - NOTE: This method currently does not work well with gothic, handwriting, or calligraphic font types;
    - the baseline of the drop cap is aligned to the baseline of the *n*th line of text (configurable with `capLines`);
    - the top of the drop cap font is aligned to the top of the text font of the first line.
- Can parse inline markdown (`DropCapText` adopted from [drop_cap_text](https://pub.dev/packages/drop_cap_text))
- Breaks pages automatically:
```dart
enum PageBreak {
  /// Break pages on the last visible word of the page.
  word,

  /// Attempt to break pages at a period, comma, semicolon, or em dash (-- / —).
  sentenceFragment,

  /// Attempt to break pages at the end of a sentence.
  sentence,

  /// Attempt to break at paragraphs (two consecutive newlines).
  paragraph;
}
```

## Getting started

This package has no dependencies other than Dart 3 / Flutter 3, and no platform-specific dependencies. (It could probably run in Dart / Flutter 2 but I don't intend to support older Flutter versions -- please fork in this case.)

## Usage

Basic usage (best in a `StatefulWidget` or other provider such as Riverpod / Flutter Hooks -- neither is required -- that you can manage state with) is as follows:

```dart
final controller = PaginatedController(PaginateData(
    // required arguments:
    text: 'Here, you should pass the text you wish to paginate...',
    dropCapLines: 3,
    style: TextStyle(fontSize: 24),

    // optional arguments:
    dropCapStyle: GoogleFonts.bellefair(),
    pageBreak: PageBreak.paragraph,
    breakLines: 1,
    resizeTolerance: 3,
    parseInlineMarkdown: true,
));

...

@override
  Widget build(BuildContext context) => PaginatedText(controller);
```

If not specified, the `dropCapStyle` will take on the same `fontFamily`, `fontWeight`, and `fontStyle` as the main body `style`. The `fontSize` of `dropCapStyle` is ignored because it is automatically sized to the number of lines specified in `dropCapLines`.

The page can be changed via `controller.next()`, `controller.previous()`, and `controller.setPageIndex(index)`.

More to come...

## Contributing

Contributions / suggestions / PRs welcome. My priority will be: bug fixes, usage in my project, improvements to API or Flutter best practices, then new features. I don't plan to introduce any dependencies but rather use the Builder pattern to afford easier integration.

## License

MIT
