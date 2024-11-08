import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'page_intent.dart';
import 'paginate_data.dart';
import 'paginated.dart';

class PaginatedText extends StatefulWidget {
  const PaginatedText({
    super.key,
    required this.data,
    this.wantKeepAlive = true,
    this.shortcuts,
    this.autofocus = true,
    this.focusNode,
    this.onFocusChange,
    this.onSelectionChanged,
  });

  final PaginateData data;
  final bool wantKeepAlive;
  final Map<ShortcutActivator, Intent>? shortcuts;
  final bool autofocus;
  final FocusNode? focusNode;
  final ValueChanged<bool>? onFocusChange;
  final ValueChanged<SelectedContent?>? onSelectionChanged;

  static const Map<ShortcutActivator, Intent> defaultShortcuts = {
    SingleActivator(LogicalKeyboardKey.home, meta: true):
        PageIntent(PageDirection.first),
    SingleActivator(LogicalKeyboardKey.home, control: true):
        PageIntent(PageDirection.first),
    SingleActivator(LogicalKeyboardKey.pageUp):
        PageIntent(PageDirection.reverse),
    SingleActivator(LogicalKeyboardKey.pageDown):
        PageIntent(PageDirection.forward),
    SingleActivator(LogicalKeyboardKey.arrowLeft):
        PageIntent(PageDirection.reverse),
    SingleActivator(LogicalKeyboardKey.arrowRight):
        PageIntent(PageDirection.forward),
    SingleActivator(LogicalKeyboardKey.end, meta: true):
        PageIntent(PageDirection.last),
    SingleActivator(LogicalKeyboardKey.end, control: true):
        PageIntent(PageDirection.last),
  };

  @override
  State<PaginatedText> createState() => _PaginatedTextState();
}

class _PaginatedTextState extends State<PaginatedText>
    with AutomaticKeepAliveClientMixin {
  int pageIndex = 0;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LayoutBuilder(builder: (context, constraints) {
      return FutureBuilder(
        future: Paginated.paginate(widget.data, constraints.biggest),
        builder: (context, snapshot) {
          final paginated = snapshot.data;
          return FocusableActionDetector(
            autofocus: widget.autofocus,
            focusNode: widget.focusNode,
            onFocusChange: widget.onFocusChange,
            shortcuts: widget.shortcuts ?? PaginatedText.defaultShortcuts,
            actions: {
              PageIntent: CallbackAction<PageIntent>(
                onInvoke: (intent) {
                  if (paginated == null) {
                    return null;
                  }
                  int index = pageIndex;
                  switch (intent.direction) {
                    case PageDirection.first:
                      index = 0;
                    case PageDirection.forward:
                      index++;
                    case PageDirection.reverse:
                      index--;
                    case PageDirection.last:
                      index = paginated.pages.length - 1;
                  }
                  index = index.clamp(0, paginated.pages.length - 1);
                  if (index == pageIndex) {
                    return null;
                  }
                  setState(() {
                    pageIndex = index;
                  });
                  return null;
                },
              ),
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Align(
                key: ValueKey(pageIndex),
                alignment: Alignment.topLeft,
                child: SelectionArea(
                  onSelectionChanged: widget.onSelectionChanged,
                  child: switch (snapshot.connectionState) {
                    ConnectionState.done => snapshot.hasError
                        ? Center(
                            child: Text(
                                'Error: ${snapshot.error}, stack: ${snapshot.stackTrace}'),
                          )
                        : snapshot.data!.page(pageIndex).widget(context),
                    _ => Center(child: CircularProgressIndicator.adaptive()),
                  },
                ),
              ),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),
          );

          // return IndexedStack(
          //   index: pageIndex,
          //   children:
          //       paginated.pages.map((page) => page.widget(context)).toList(),
          // );
          // final page = paginated.page(pageIndex);
          // return page.widget(context);
        },
      );
    });
  }

  @override
  bool get wantKeepAlive => widget.wantKeepAlive;
}
