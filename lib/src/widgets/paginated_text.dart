import 'package:flutter/material.dart';
import 'package:paginated_text/paginated_text.dart';

typedef PaginatedTextBuilderFunction = Widget Function(
    BuildContext context, Widget child);

class PaginatedText extends StatelessWidget {
  const PaginatedText(
    this.controller, {
    super.key,
    this.builder,
  });

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
        final child = LayoutBuilder(builder: (context, constraints) {
          final currentPage = controller.currentPage;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            controller.updateLayoutSize(constraints.biggest);
          });

          return DropCapText(
            key: ValueKey(currentPage.pageIndex),
            currentPage.text,
            parseInlineMarkdown: controller.paginateData.parseInlineMarkdown,
            style: controller.paginateData.style,
            dropCapStyle: controller.paginateData.dropCapStyle,
            dropCapChars: currentPage.pageIndex == 0 ? 1 : 0,
            capLines: controller.paginateData.dropCapLines,
          );
        });

        return builder?.call(context, child) ?? child;
      },
    );
  }
}