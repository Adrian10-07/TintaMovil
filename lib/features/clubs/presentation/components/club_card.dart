import 'package:flutter/material.dart';

import '../../domain/entities/club.dart';
import '../../domain/entities/club_member.dart';

/// Tarjeta visual para un club en el listado.
///
/// Usa Material 3 Card con theming del proyecto, sin harcodear colores.
class ClubCard extends StatelessWidget {
  final Club club;
  final ClubRole? memberRole;
  final VoidCallback? onTap;

  const ClubCard({
    super.key,
    required this.club,
    this.memberRole,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  club.name.isNotEmpty ? club.name[0].toUpperCase() : '?',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            club.name,
                            style: textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (club.isPrivate)
                          Icon(Icons.lock_rounded,
                              size: 14, color: colorScheme.onSurfaceVariant),
                      ],
                    ),
                    if (club.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        club.description,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.group_rounded,
                            size: 14, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          '${club.memberCount}',
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (club.category != null) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.category_rounded,
                              size: 14,
                              color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              club.category!,
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        if (memberRole != null) ...[
                          const Spacer(),
                          Chip(
                            label: Text(memberRole!.name),
                            labelStyle: textTheme.labelSmall,
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Chevron
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
