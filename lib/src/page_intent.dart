import 'package:flutter/widgets.dart';

class PageIntent extends Intent {
  const PageIntent(this.direction);

  final PageDirection direction;
}

enum PageDirection {
  first,
  forward,
  reverse,
  last,
}
