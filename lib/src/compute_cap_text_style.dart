import 'dart:collection';
import 'dart:ui';

import 'package:flutter/painting.dart';

import 'cap_style.dart';

// Cache letter height info for each font family.
final _letterHeightInfoCache = HashMap<int, LetterHeightInfo>();

// Font size used to compute the letter height ratio.
const double _letterHeightCalcFontSize = 3600.0;

// Default letter height ratio determined from default font family.
const double _defaultLetterHeightRatio = 2536.0 / 3600.0;

final LetterHeightInfo _defaultLetterHeightInfo = LetterHeightInfo(
  topFrac: 0.0, // TODO: COMPUTE!
  bottomFrac: 0.0, // TODO: COMPUTE!
  baselineFrac: 1.0 - _defaultLetterHeightRatio,
  ratio: _defaultLetterHeightRatio,
);

final class CapMetrics {
  final TextStyle capTextStyle;
  final LetterHeightInfo capHeightInfo;
  final LetterHeightInfo textHeightInfo;

  const CapMetrics({
    required this.capTextStyle,
    required this.capHeightInfo,
    required this.textHeightInfo,
  });
}

Future<CapMetrics> computeCapMetrics({
  required final CapStyle capStyle,
  required final TextStyle textStyle,
  required final double lineHeight,
  required final TextScaler textScaler,
  required final int capLines,
}) async {
  final textBaseStyle = CapStyle.fromStyle(textStyle);
  final textHeightInfo = await _computeLetterHeightInfo(textBaseStyle);
  final capHeightInfo = await _computeLetterHeightInfo(capStyle);
  final textFontSize = textStyle.fontSize ?? textScaler.scale(14.0);

  final capFontSize = _computeCapFontSize(
    textFontSize: textFontSize,
    lineHeight: lineHeight,
    capLines: capLines,
    textLetterHeightRatio: textHeightInfo.ratio,
    capLetterHeightRatio: capHeightInfo.ratio,
  );

  return CapMetrics(
    capTextStyle: capStyle.textStyle(capFontSize),
    capHeightInfo: capHeightInfo,
    textHeightInfo: textHeightInfo,
  );
}

double _computeCapFontSize({
  required double textFontSize,
  required double lineHeight,
  required int capLines,
  required double textLetterHeightRatio,
  required double capLetterHeightRatio,
}) {
  final wantedCapLetterHeight =
      (lineHeight * (capLines - 1) + (textFontSize * textLetterHeightRatio))
          .ceil();
  return (wantedCapLetterHeight / capLetterHeightRatio).ceilToDouble();
}

class LetterHeightInfo {
  final double ratio;
  final double topFrac;
  final double baselineFrac;
  final double bottomFrac;

  const LetterHeightInfo({
    required this.ratio,
    required this.topFrac,
    required this.baselineFrac,
    required this.bottomFrac,
  });
}

Future<LetterHeightInfo> _computeLetterHeightInfo(CapStyle capStyle) async {
  final hash =
      Object.hash(capStyle.fontFamily, capStyle.fontWeight, capStyle.fontStyle);
  GlyphInfo;
  if (_letterHeightInfoCache.containsKey(hash)) {
    // print(
    //     'CACHED letterHeightInfo: ${_letterHeightInfoCache[hash]!}, capStyle: $capStyle');
    return _letterHeightInfoCache[hash]!;
  }
  final painter = TextPainter(
    text: TextSpan(
      text: 'Z',
      style: TextStyle(
        fontFamily: capStyle.fontFamily,
        fontWeight: capStyle.fontWeight,
        fontStyle: capStyle.fontStyle,
        fontSize: _letterHeightCalcFontSize,
      ),
    ),
    textScaler: TextScaler.noScaling,
    textDirection: TextDirection.ltr,
  )..layout();
  final box = painter
      .getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: 1))
      .first;
  // print('box: $box');
  // print('painter: ${painter.size}');
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);
  painter.paint(canvas, Offset(0, -box.top));
  final picture = recorder.endRecording();
  final image = await picture.toImage(
      painter.width.ceil(), (box.bottom - box.top).ceil());
  // print('image.height: ${image.height}');
  final bytes = await image.toByteData(format: ImageByteFormat.rawRgba);
  if (bytes == null) {
    _letterHeightInfoCache[hash] = _defaultLetterHeightInfo;
    return _defaultLetterHeightInfo;
  }
  final x = (image.width / 2).round();
  final line = List<bool>.generate(image.height, (y) {
    // https://github.com/marcglasberg/image_pixels/blob/master/lib/src/image_pixels.dart#L194
    final offset = 4 * (x + (y * image.width));
    // https://github.com/marcglasberg/image_pixels/blob/master/lib/src/image_pixels.dart#214
    final pixel = bytes.getUint32(offset);
    return pixel > 0;
  });
  final height = image.height.toDouble();
  final top = line.indexWhere((y) => y).toDouble();
  final baseline = line.lastIndexWhere((y) => y).toDouble();
  // print(
  //     'LETTER img height: $height, top: $top, baseline: $baseline, baselineFrac: ${baseline / height}');
  final letterHeight = (baseline - top).toDouble();

  final ratio = letterHeight / _letterHeightCalcFontSize;
  final letterHeightInfo = LetterHeightInfo(
    topFrac: top / height,
    bottomFrac: (height - baseline) / height,
    baselineFrac: baseline / height,
    ratio: ratio,
  );
  // print('COMPUTED letterHeightInfo: $letterHeightInfo, capStyle: $capStyle');

  _letterHeightInfoCache[hash] = letterHeightInfo;
  return letterHeightInfo;
}
