## 0.3.1
* Fix `FittedText.fit`: replace end-of-line computation `getPositionForOffset` with `getLineBoundary` from start of line, because a Flutter bug gives the wrong offset (next line starting character) at the right end of the line, instead of the last offset in the line. `getLineBoundary` seems to fix it.

## 0.3.0
* Replace hard-coded `textStyle` defaults with `DefaultTextStyle.of(context)` to fix bug that rendered lines wrapped earlier than computed lines, which resulted in text at the end of cap lines being cut off, especially when `textScaler` is something other than `TextScaler.noScaling`.

## 0.2.0
* Replace instances of `RichText` with `Text.rich` so that `PaginatedText` can be wrapped in a `SelectionArea` and made selectable.
* Fix layout differences between `RichText` and `Text.rich`.

## 0.1.0
* Add manual / hard page break feature.
* Fix computation of drop cap width temporarily (use default cap height).
* Fix pagination to take textScaler and hard breaks into account .

## 0.0.4
* Fix link to screen demo.

## 0.0.3
* Fix typo in pubspec.yaml.
* Make screen animated GIF smaller.

## 0.0.2
* Fix pub.dev analyzer issues.

## 0.0.1

* initial release.
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
- Breaks pages automatically.