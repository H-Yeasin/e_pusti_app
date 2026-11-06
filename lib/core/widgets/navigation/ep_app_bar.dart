import 'package:flutter/material.dart';

/// Inner-screen app bar: "← title" with optional trailing actions.
class EpAppBar extends StatelessWidget implements PreferredSizeWidget {
  const EpAppBar({super.key, required this.title, this.actions});

  final String title;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: actions,
    );
  }
}
