import 'package:flutter/material.dart';

/// AppBar del lector: título + bookmark + menú.
class ReaderAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  final bool isBookmarked;
  final VoidCallback onBookmarkTap;
  final VoidCallback onBack;

  const ReaderAppBar({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.isBookmarked,
    required this.onBookmarkTap,
    required this.onBack,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: onBack,
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.55),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            color: isBookmarked ? colorScheme.tertiary : colorScheme.onSurface,
          ),
          onPressed: onBookmarkTap,
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}