import 'package:flutter/material.dart';
import 'package:tinta/core/localization/app_strings.dart';
import 'package:tinta/core/ui/theme3material/theme.dart';
import '../../../achievements/data/services/achievement_service.dart';
import '../../../auth/domain/entities/user.dart';
import 'edit_profile_sheet.dart';
import 'user_avatar.dart';


class ProfileHeaderSection extends StatelessWidget {
  final User profile;
  final int achievementPoints;
  final Future<bool> Function({String? name, String? language}) onSaveEdit;

  const ProfileHeaderSection({
    super.key,
    required this.profile,
    required this.achievementPoints,
    required this.onSaveEdit,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final t = AppStrings.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UserAvatar(
          name: profile.name,
          // `User.avatarUrl` es un String no-nullable en la entidad;
          // uso isNotEmpty para saber si mando null al avatar (que
          // dispara el fallback con inicial).
          avatarUrl:
          profile.avatarUrl.isNotEmpty ? profile.avatarUrl : null,
          size: 76,
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(profile.name, style: textTheme.headlineSmall),
              const SizedBox(height: 2),
              Text(
                profile.email,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.50),
                ),
              ),
              const SizedBox(height: 6),
              _BadgesRow(
                role: profile.role,
                achievementPoints: achievementPoints,
              ),
              const SizedBox(height: 6),
              Text(
                '${t.memberSince} ${_formatDate(profile.createdAt)}',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => EditProfileSheet.show(
            context,
            currentName: profile.name,
            currentLanguage: profile.language,
            onSave: onSaveEdit,
          ),
          icon: Icon(
            Icons.edit_outlined,
            size: 20,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }

  // Formato "mmm YYYY" en español — chico y contenido en esta sección.
  String _formatDate(DateTime date) {
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

/// Fila con los dos badges: rol y nivel de lector (logros).
class _BadgesRow extends StatelessWidget {
  final String role;
  final int achievementPoints;

  const _BadgesRow({required this.role, required this.achievementPoints});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        // Badge de rol.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            role.toUpperCase(),
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        // Badge de nivel de lector — reuso MaterialTheme.warmGold.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: MaterialTheme.warmGold.withOpacity(0.25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.military_tech_rounded,
                size: 12,
                color: MaterialTheme.warmGold,
              ),
              const SizedBox(width: 3),
              Text(
                AchievementService.levelFor(achievementPoints).title,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}