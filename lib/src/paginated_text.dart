import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'page_intent.dart';
import 'paginate_data.dart';
import 'paginated.dart';

typedef PaginatedTextBuilder = Widget Function(
    BuildContext context, Paginated value, Widget child);

class PaginatedText extends StatefulWidget {
  const PaginatedText({
    super.key,
    required this.data,
    required this.pageIndex,
    this.builder,
    this.wantKeepAlive = true,
    this.actionsBuilder,
    this.shortcuts,
    this.autofocus = true,
    this.focusNode,
    this.onFocusChange,
    this.onSelectionChanged,
  });

  final PaginateData data;
  final int pageIndex;
  final PaginatedTextBuilder? builder;
  final bool wantKeepAlive;
  final Map<ShortcutActivator, Intent>? shortcuts;
  final Map<Type, Action<Intent>> Function(Paginated)? actionsBuilder;
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
    SingleActivator(LogicalKeyboardKey.arrowDown):
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
  Size _size = Size.zero;
  late FocusNode _focusNode;
  late final StreamController<Paginated> _paginatedController;
  late int pageIndex = widget.pageIndex;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _paginatedController = StreamController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _size = MediaQuery.sizeOf(context);
    _updatePaginated();
  }

  @override
  void didUpdateWidget(covariant PaginatedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    setState(() {
      pageIndex = widget.pageIndex;
    });
    _updatePaginated();
  }

  Future<void> _updatePaginated() async {
    await _paginatedController.addStream(
      Stream.fromFuture(Paginated.paginate(widget.data, _size)),
    );
  }

  void _updateSizeIfNeeded(Size size) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || size == _size || size.height == 0 || size.width == 0) {
        return;
      }

      setState(() {
        _size = size;
      });
      _updatePaginated();
    });
  }

  @override
  void dispose() {
    super.dispose();
    _focusNode.dispose();
  }

  @override
  bool get wantKeepAlive => widget.wantKeepAlive;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamBuilder<Paginated>(
      stream: _paginatedController.stream,
      builder: (context, snapshot) {
        final Paginated? paginated = snapshot.data;

        if (paginated == null) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        final child = LayoutBuilder(builder: (context, constraints) {
          _updateSizeIfNeeded(constraints.biggest);

          return FocusableActionDetector(
            autofocus: widget.autofocus,
            focusNode: widget.focusNode,
            onFocusChange: widget.onFocusChange,
            shortcuts: widget.shortcuts ?? PaginatedText.defaultShortcuts,
            actions: widget.actionsBuilder?.call(paginated) ??
                {
                  PageIntent: CallbackAction<PageIntent>(
                    onInvoke: (intent) {
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
                      setState(() {
                        pageIndex = index;
                      });
                      return null;
                    },
                  ),
                },
            child: SelectionArea(
              onSelectionChanged: widget.onSelectionChanged,
              child: paginated.page(pageIndex).widget(context),
            ),
          );
        });

        return widget.builder?.call(
              context,
              paginated,
              child,
            ) ??
            child;
      },
    );
  }
}
