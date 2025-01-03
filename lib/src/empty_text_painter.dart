import 'package:flutter/material.dart';

final emptyTextPainter =
    TextPainter(text: TextSpan(text: ''), textDirection: TextDirection.ltr)
      ..layout();
