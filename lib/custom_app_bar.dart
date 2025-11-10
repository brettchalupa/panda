import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Custom AppBar that includes window controls and drag-to-move area
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      title: DragToMoveArea(
        child: Row(children: [Expanded(child: title)]),
      ),
      actions: [
        ...?actions,
        if (actions != null) const SizedBox(width: 8),
        const WindowButtons(),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Window control buttons for title bar
class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.minimize, size: 20),
          onPressed: () => windowManager.minimize(),
          tooltip: 'Minimize',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        ),
        IconButton(
          icon: const Icon(Icons.crop_square, size: 18),
          onPressed: () async {
            if (await windowManager.isMaximized()) {
              windowManager.unmaximize();
            } else {
              windowManager.maximize();
            }
          },
          tooltip: 'Maximize',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 20),
          onPressed: () => windowManager.close(),
          tooltip: 'Close',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        ),
      ],
    );
  }
}
