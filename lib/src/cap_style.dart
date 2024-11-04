import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

final class CapStyle {
  final Color? color;
  final String? fontFamily;
  final FontWeight? fontWeight;
  final FontStyle? fontStyle;

  const CapStyle({
    required this.fontFamily,
    required this.fontWeight,
    required this.fontStyle,
    required this.color,
  });

  TextStyle textStyle(double fontSize) {
    return TextStyle(
      fontFamily: fontFamily,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      color: color,
      fontSize: fontSize,
    );
  }

  factory CapStyle.fromStyle(TextStyle style) => CapStyle(
        fontFamily: style.fontFamily,
        fontWeight: style.fontWeight,
        fontStyle: style.fontStyle,
        color: style.color,
      );

  @override
  int get hashCode => Object.hash(fontFamily, fontWeight, fontStyle);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CapStyle &&
          fontFamily == other.fontFamily &&
          fontWeight == other.fontWeight &&
          fontStyle == other.fontStyle);

  @override
  String toString() => '''
  ${objectRuntimeType(this, 'CapStyle')}(
    fontFamily: $fontFamily,
    fontWeight: $fontWeight,
    fontStyle: $fontStyle,
    color: $color
  )''';
}
