import 'package:flutter/material.dart';
import 'package:tinta/core/localization/app_strings.dart';
import 'package:tinta/core/ui/theme3material/theme.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../clubs/data/services/captcha_gate_service.dart';

/// Sección "Cuenta" de la pantalla de perfil.
class AccountInfoSection extends StatelessWidget {
  final User profile;

  const AccountInfoSection({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final t = AppStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.account, style: textTheme.headlineSmall),
        const SizedBox(height: 14),
        _InfoCard(
          children: [
            _AntirobotRow(userId: profile.id),
            _CardDivider(),
            _InfoRow(
              label: t.idiomaLabel,
              value: profile.language == 'es' ? 'Español' : 'English',
              icon: Icons.language_rounded,
            ),
          ],
        ),
      ],
    );
  }
}

/// Fila especial de "antirobot": escucha cambios en `CaptchaGateService`
/// para reflejarlos sin tener que recargar la pantalla.
class _AntirobotRow extends StatelessWidget {
  final String userId;
  const _AntirobotRow({required this.userId});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<int>(
      valueListenable: CaptchaGateService.changes,
      builder: (context, _, __) {
        return FutureBuilder<bool>(
          future: CaptchaGateService.hasPassed(userId),
          builder: (context, snapshot) {
            final passed = snapshot.data ?? false;
            return _InfoRow(
              label: 'Antirobot',
              value: passed ? 'Verificado' : 'Desconocido',
              icon: passed
                  ? Icons.verified_rounded
                  : Icons.warning_amber_rounded,
              iconColor:
              passed ? colorScheme.primary : MaterialTheme.warmGold,
            );
          },
        );
      },
    );
  }
}

/// Contenedor tipo tarjeta que agrupa las filas de info.
class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      child: Column(children: children),
    );
  }
}

/// Fila individual (icono + label + valor).
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final effectiveColor = iconColor ?? colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: effectiveColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: effectiveColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label, style: textTheme.titleSmall),
          ),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.60),
            ),
          ),
        ],
      ),
    );
  }
}

/// Divisor sutil entre filas dentro de la tarjeta.
class _CardDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4),
      height: 1,
      indent: 56,
    );
  }
}