import 'package:flutter/material.dart';
import 'package:paginated_text/paginated_text.dart';

import 'drop_cap_text.dart';

/// Defines the builder function for `PaginatedText.builder`.
typedef PaginatedTextBuilderFunction = Widget Function(
    BuildContext context, Widget child);

/// Built-in package widget that provides a basic view for the `PaginatedController`.
/// A `builder` can be passed, or you can use a totally custom widget with just the `controller`.
class PaginatedText extends StatelessWidget {
  const PaginatedText(
    this.controller, {
    super.key,
    this.builder,
  });

  @override
  ValueKey get key => ValueKey(controller.currentPage);

  /// Called at layout time to construct the widget tree.
  ///
  /// The builder must not return null.
  final PaginatedTextBuilderFunction? builder;

  final PaginatedController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final child = DropCapText(
          key: ValueKey(controller.currentPage.pageIndex),
          controller.currentPage.text,
          parseInlineMarkdown: controller.paginateData.parseInlineMarkdown,
          style: controller.paginateData.style,
          dropCapStyle: controller.paginateData.dropCapStyle,
          dropCapPadding: controller.paginateData.dropCapPadding,
          capLines: controller.currentPage.pageIndex == 0
              ? controller.paginateData.dropCapLines
              : 0,
          textScaler: controller.paginateData.textScaler,
        );

        return LayoutBuilder(builder: (context, constraints) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            controller.updateLayoutSize(constraints.biggest);
          });

          return builder?.call(context, child) ?? child;
        });
      },
    );
  }
}
