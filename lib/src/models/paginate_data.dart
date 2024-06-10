import 'package:flutter/material.dart';

class PaginateData {
  final String text;
  final TextStyle style;
  final int dropCapLines;
  final TextStyle? dropCapStyle;
  final TextDirection textDirection;
  final TextScaler textScaler;
  final double sizeTolerance;

  const PaginateData({
    required this.text,
    required this.style,
    required this.dropCapLines,
    this.dropCapStyle,
    this.textDirection = TextDirection.ltr,
    this.textScaler = TextScaler.noScaling,
    this.sizeTolerance = 2.0,
  });

  PaginateData copyWith({
    String? text,
    TextStyle? style,
    int? dropCapLines,
    TextStyle? dropCapStyle,
    bool clearDropCapStyle = false,
    TextDirection? textDirection,
    TextScaler? textScaler,
    double? sizeTolerance,
  }) =>
      PaginateData(
        text: text ?? this.text,
        style: style ?? this.style,
        dropCapStyle:
            dropCapStyle ?? (clearDropCapStyle ? null : this.dropCapStyle),
        dropCapLines: dropCapLines ?? this.dropCapLines,
        textDirection: textDirection ?? this.textDirection,
        textScaler: textScaler ?? this.textScaler,
        sizeTolerance: sizeTolerance ?? this.sizeTolerance,
      );

  @override
  int get hashCode => Object.hash(
      text, style, dropCapLines, dropCapStyle, textDirection, textScaler);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PaginateData &&
          text == other.text &&
          style == other.style &&
          dropCapLines == other.dropCapLines &&
          dropCapStyle == other.dropCapStyle &&
          textDirection == other.textDirection &&
          textScaler == other.textScaler &&
          sizeTolerance == other.sizeTolerance);
}
