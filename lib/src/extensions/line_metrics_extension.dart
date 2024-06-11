import 'package:flutter/material.dart';

extension LineMetricsExtension on LineMetrics {
  double get top => baseline - ascent;
  double get bottom => baseline + descent;
  double get right => left + width - 1.0;
  Offset get leftTop => Offset(left, top);
  Offset get rightTop => Offset(right, top);
  Offset get leftBaseline => Offset(left, baseline);
  Offset get rightBaseline => Offset(right, baseline);
}
