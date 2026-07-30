import 'package:flutter/material.dart';
import 'package:tinta/core/di/service_locator.dart';
import 'package:tinta/core/localization/app_strings.dart';
import 'package:tinta/main.dart' show appSettings;
import '../../../../globals.dart';
import '../../../achievements/data/services/achievement_service.dart';
import '../../../achievements/presentation/views/achievements_view.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/presentation/views/forgot_password_view.dart';
import '../views/appearance_settings_view.dart';
import '../views/help_support_view.dart';
import '../views/notification_settings_view.dart';
import '../views/privacy_control_view.dart';
import '../views/security_info_view.dart';
import 'profile_menu_item.dart';


class SettingsSection extends StatelessWidget {
  // Uso `User` (auth) porque es la entidad real que expone UserViewModel.
  final User profile;
  final int achievementPoints;
  final VoidCallback onLogoutRequested;

  const SettingsSection({
    super.key,
    required this.profile,
    required this.achievementPoints,
    required this.onLogoutRequested,
  });

  // Extraigo la navegación a un helper para no repetir el patrón
  // `Navigator.push(context, MaterialPageRoute(...))` 8 veces.
  void _navigate(BuildContext context, Widget page, {VoidCallback? onReturn}) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page))
        .then((_) => onReturn?.call());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final t = AppStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.settings, style: textTheme.headlineSmall),
        const SizedBox(height: 8),
        _MenuCard(children: [
          ProfileMenuItem(
            icon: Icons.emoji_events_outlined,
            label: 'Logros',
            subtitle:
            '$achievementPoints puntos · ${AchievementService.levelFor(achievementPoints).title}',
            onTap: () => _navigate(
              context,
              AchievementsView(userId: profile.id),
            ),
          ),
          ProfileMenuItem(
            icon: Icons.shield_outlined,
            label: 'Seguridad',
            subtitle: 'Cómo protegemos tu cuenta',
            onTap: () => _navigate(context, const SecurityInfoView()),
          ),
          ProfileMenuItem(
            icon: Icons.notifications_outlined,
            label: t.notifications,
            subtitle: t.notificationsSubtitle,
            onTap: () => _navigate(
              context,
              NotificationSettingsView(userId: profile.id),
            ),
          ),
          ProfileMenuItem(
            icon: Icons.palette_outlined,
            label: t.appearance,
            subtitle: t.appearanceSubtitle,
            onTap: () => _navigate(
              context,
              AppearanceSettingsView(controller: appSettings),
            ),
          ),
          ProfileMenuItem(
            icon: Icons.lock_outline_rounded,
            label: t.privacy,
            subtitle: t.privacySubtitle,
            onTap: () => _navigate(
              context,
              PrivacyControlView(userId: profile.id),
            ),
          ),
          ProfileMenuItem(
            icon: Icons.lock_reset_rounded,
            label: 'Restablecer contraseña',
            subtitle: 'Te mandamos un código a tu correo',
            onTap: () => _navigate(
              context,
              ForgotPasswordView(
                authRepository: sl<AuthRepository>(),
                userId: profile.id,
                initialEmail: profile.email,
              ),
            ),
          ),
          ProfileMenuItem(
            icon: Icons.help_outline_rounded,
            label: t.helpSupport,
            onTap: () => _navigate(
              context,
              HelpSupportView(userEmail: profile.email),
            ),
          ),
          ProfileMenuItem(
            icon: Icons.logout_rounded,
            label: t.logout,
            iconColor: colorScheme.error,
            showChevron: false,
            onTap: onLogoutRequested,
          ),
        ]),
      ],
    );
  }
}

/// Tarjeta contenedora del menú, con divisores automáticos entre items.
class _MenuCard extends StatelessWidget {
  final List<Widget> children;
  const _MenuCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // Intercalo divisores entre items automáticamente — antes se
      // construían a mano en el `expand` original.
      child: Column(
        children: children
            .expand((child) => [
          child,
          if (child != children.last)
            Divider(
              color: colorScheme.outlineVariant.withOpacity(0.4),
              height: 1,
              indent: 56,
            ),
        ])
            .toList(),
      ),
    );
  }
}