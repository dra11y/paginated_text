import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'paginate_data.dart';
import 'paginated.dart';

class PaginatedText extends StatefulWidget {
  const PaginatedText({
    super.key,
    required this.data,
    this.wantKeepAlive = true,
  });

  final PaginateData data;
  final bool wantKeepAlive;

  @override
  State<PaginatedText> createState() => _PaginatedTextState();
}

enum PageDirection {
  forward,
  reverse,
}

class PageIntent extends Intent {
  const PageIntent(this.direction);

  final PageDirection direction;
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
            autofocus: true,
            shortcuts: {
              SingleActivator(LogicalKeyboardKey.arrowLeft):
                  PageIntent(PageDirection.reverse),
              SingleActivator(LogicalKeyboardKey.arrowRight):
                  PageIntent(PageDirection.forward),
            },
            actions: {
              PageIntent: CallbackAction<PageIntent>(
                onInvoke: (intent) {
                  if (paginated == null) {
                    return null;
                  }
                  int index = pageIndex;
                  if (intent.direction == PageDirection.forward) {
                    index++;
                  } else {
                    index--;
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
