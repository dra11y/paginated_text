# paginated_text

A Flutter package that provides a paginated text view with optional auto-sized initial drop cap.

## WIP - Work in Progress

## Features

- Text is paginated automatically to fit in the widget's layout size;
- The first letter can be a drop cap that is automatically positioned and sized:
    - the actual letter height(s) (using the letter 'Z') of the cap and text fonts is/are computed and cached:
        - Flutter currently provides no internal means to get the actual letter height of a font, therefore it must be painted, converted to an image, and inspected for the top/bottom pixels of the 'Z';
        - The result is cached (once each run for each font family, weight, and style) as a ratio and used to compute the font size from the desired letter height;
    - the baseline of the drop cap is aligned to the baseline of the *n*th line of text (configurable with `capLines`);
    - the top of the drop cap font is aligned to the top of the text font of the first line.

## Getting started

This package has no dependencies other than Flutter 3, and no platform-specific dependencies. (It could probably run in Flutter 2 but I don't intend to support older Flutter versions.)

## Usage

Basic usage (best in a `StatefulWidget` or other provider such as Riverpod / Flutter Hooks that you can manage state with) is as follows:

```dart
final controller = PaginatedController(PaginateData(
    text: 'Here, you should pass the text you wish to paginate...',
    dropCapLines: 3,
    style: TextStyle(fontSize: 24),
));

...

@override
  Widget build(BuildContext context) => PaginatedText(controller);
```

If not specified, the `dropCapStyle` will take on the same `fontFamily`, `fontWeight`, and `fontStyle` as the main body `style`. The `fontSize` of `dropCapStyle` is ignored because it is automatically sized to the number of lines specified in `dropCapLines`.

The page can be changed via `controller.next()`, `controller.previous()`, and `controller.setPageIndex(index)`.

More to come...
