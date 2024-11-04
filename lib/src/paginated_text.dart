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
        future: Paginated.paginate(widget.data, constraints.biggest),
        builder: (context, snapshot) {
          final paginated = snapshot.data;
          if (paginated == null) {
            return Center(child: CircularProgressIndicator.adaptive());
          }
          final page = paginated.page(pageIndex);
          return page.build();
        },
      );
    });
  }

  @override
  bool get wantKeepAlive => widget.wantKeepAlive;
}
