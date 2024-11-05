import 'package:flutter/material.dart';

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

class _PaginatedTextState extends State<PaginatedText>
    with AutomaticKeepAliveClientMixin {
  int pageIndex = 0;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LayoutBuilder(builder: (context, constraints) {
      return FutureBuilder(
        future: Paginated.paginate(
            widget.data, Size(constraints.maxWidth, constraints.maxHeight)),
        builder: (context, snapshot) {
          final paginated = snapshot.data;
          if (paginated == null) {
            final error = snapshot.error;
            if (error != null) {
              throw error;
            }
            return Center(child: CircularProgressIndicator.adaptive());
          }
          final page = paginated.page(pageIndex);
          return page.widget(context);
        },
      );
    });
  }

  @override
  bool get wantKeepAlive => widget.wantKeepAlive;
}
