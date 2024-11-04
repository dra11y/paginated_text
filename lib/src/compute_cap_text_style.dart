import 'dart:collection';
import 'dart:ui';

import 'package:flutter/painting.dart';

import 'cap_style.dart';

// Cache letter height to font size ratios for each font family.
final _letterHeightRatioCache = HashMap<int, double>();

// Font size used to compute the letter height ratio.
const double _letterHeightCalcFontSize = 3600.0;

// Default letter height ratio determined from default font family.
const double _defaultLetterHeightRatio = 2536.0 / 3600.0;

Future<TextStyle> computeCapTextStyle({
  required final CapStyle capStyle,
  required final TextStyle textStyle,
  required final double lineHeight,
  required final TextScaler textScaler,
  required final int capLines,
}) async {
  final textBaseStyle = CapStyle.fromStyle(textStyle);
  final textHeightRatio = await _computeLetterHeightRatio(textBaseStyle);
  final capHeightRatio = await _computeLetterHeightRatio(capStyle);
  final textFontSize = textStyle.fontSize ?? textScaler.scale(14.0);

  final capFontSize = _computeCapFontSize(
    textFontSize: textFontSize,
    lineHeight: lineHeight,
    capLines: capLines,
    textLetterHeightRatio: textHeightRatio,
    capLetterHeightRatio: capHeightRatio,
  );

  return capStyle.textStyle(capFontSize);
}

double _computeCapFontSize({
  required double textFontSize,
  required double lineHeight,
  required int capLines,
  required double textLetterHeightRatio,
  required double capLetterHeightRatio,
}) {
  final wantedCapLetterHeight = ((textFontSize * lineHeight) * (capLines - 1) +
          (textFontSize * textLetterHeightRatio))
      .ceil();
  return (wantedCapLetterHeight / capLetterHeightRatio).ceilToDouble();
}

Future<double> _computeLetterHeightRatio(CapStyle capstyle) async {
  final hash =
      Object.hash(capstyle.fontFamily, capstyle.fontWeight, capstyle.fontStyle);
  if (_letterHeightRatioCache.containsKey(hash)) {
    return _letterHeightRatioCache[hash]!;
  }
  final painter = TextPainter(
    text: TextSpan(
      text: 'Z',
      style: TextStyle(
        fontFamily: capstyle.fontFamily,
        fontWeight: capstyle.fontWeight,
        fontStyle: capstyle.fontStyle,
        fontSize: _letterHeightCalcFontSize,
      ),
    ),
    textScaler: TextScaler.noScaling,
    textDirection: TextDirection.ltr,
  )..layout();
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);
  painter.paint(canvas, Offset.zero);
  final picture = recorder.endRecording();
  final image =
      await picture.toImage(painter.width.ceil(), painter.height.ceil());
  final bytes = await image.toByteData(format: ImageByteFormat.rawRgba);
  if (bytes == null) {
    _letterHeightRatioCache[hash] = _defaultLetterHeightRatio;
    return _defaultLetterHeightRatio;
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

  final ratio = letterHeight / _letterHeightCalcFontSize;
  _letterHeightRatioCache[hash] = ratio;
  return ratio;
}
