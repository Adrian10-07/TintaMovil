import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tinta/core/ui/theme3material/theme.dart';
import 'package:tinta/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../viewmodels/user_viewmodel.dart';
import '../../../../core/presentation/components/tinta_background.dart';
import '../components/user_avatar.dart';
import '../components/profile_menu_item.dart';
import '../components/edit_profile_sheet.dart';
import '../../../../core/di/service_locator.dart';

/// Pantalla de perfil del usuario (Tab "Yo").
///
/// Campos disponibles del backend Identity:
/// id, email, name, role, email_verified, avatar_url, language, created_at, updated_at
class UserView extends StatefulWidget {
  const UserView({Key? key}) : super(key: key);

  @override
  State<UserView> createState() => _UserViewState();
}

class _UserViewState extends State<UserView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserViewModel>().loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Mi perfil'),
          ),
          body: TintaBackground(
            blobs: [
              BlobConfig(
                top: -100,
                right: -60,
                color: Theme.of(context).colorScheme.primary,
                size: 260,
                opacity: 0.10,
              ),
              BlobConfig(
                bottom: -80,
                left: -60,
                color: MaterialTheme.warmGold,
                size: 220,
                opacity: 0.08,
              ),
            ],
            child: SafeArea(
              child: _buildContent(context, vm),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, UserViewModel vm) {
    if (vm.state == UserState.loading && vm.profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.state == UserState.error && vm.profile == null) {
      return _ErrorState(
        message: vm.errorMessage,
        onRetry: vm.loadProfile,
      );
    }

    final profile = vm.profile;
    if (profile == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: vm.loadProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // ── Header del perfil ──────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserAvatar(
                  name: profile.name,
                  avatarUrl: profile.avatarUrl.isNotEmpty
                      ? profile.avatarUrl
                      : null,
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
                      // Badge de rol
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          profile.role.toUpperCase(),
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Miembro desde ${_formatDate(profile.createdAt)}',
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
                    onSave: ({name, language}) =>
                        context.read<UserViewModel>().updateProfile(
                          name: name,
                          language: language,
                        ),
                  ),
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── Info de la cuenta ──────────────────────────────────
            Text('Cuenta', style: textTheme.headlineSmall),
            const SizedBox(height: 14),
            _InfoCard(
              children: [
                _InfoRow(
                  label: 'Correo verificado',
                  value: profile.emailVerified ? 'Sí' : 'No',
                  icon: profile.emailVerified
                      ? Icons.verified_rounded
                      : Icons.warning_amber_rounded,
                  iconColor: profile.emailVerified
                      ? colorScheme.primary
                      : MaterialTheme.warmGold,
                ),
                Divider(
                  color: colorScheme.outlineVariant.withOpacity(0.4),
                  height: 1,
                  indent: 56,
                ),
                _InfoRow(
                  label: 'Idioma',
                  value: profile.language == 'es' ? 'Español' : 'English',
                  icon: Icons.language_rounded,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── Configuración ──────────────────────────────────────
            Text('Configuración', style: textTheme.headlineSmall),
            const SizedBox(height: 8),
            _MenuSection(children: [
              ProfileMenuItem(
                icon: Icons.notifications_outlined,
                label: 'Notificaciones',
                subtitle: 'Gestiona tus alertas de lectura',
                onTap: () {},
              ),
              ProfileMenuItem(
                icon: Icons.palette_outlined,
                label: 'Apariencia',
                subtitle: 'Tema y tamaño del texto',
                onTap: () {},
              ),
              ProfileMenuItem(
                icon: Icons.lock_outline_rounded,
                label: 'Privacidad',
                subtitle: 'Control de tus datos',
                onTap: () {},
              ),
              ProfileMenuItem(
                icon: Icons.help_outline_rounded,
                label: 'Ayuda y soporte',
                onTap: () {},
              ),
              ProfileMenuItem(
                icon: Icons.logout_rounded,
                label: 'Cerrar sesión',
                iconColor: colorScheme.error,
                showChevron: false,
                onTap: () => _showLogoutDialog(context),
              ),
            ]),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text(
          '¿Estás seguro de que quieres cerrar tu sesión en Tinta?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Implementar logout real usando sl ya que AuthViewModel no está en este árbol
              final authVM = sl<AuthViewModel>();
              authVM.logout().then((_) {
                if (context.mounted) {
                  context.read<UserViewModel>().clearProfile();
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                }
              });
            },
            child: Text(
              'Cerrar sesión',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets privados
// ─────────────────────────────────────────────────────────────────────────────

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

class _MenuSection extends StatelessWidget {
  final List<Widget> children;
  const _MenuSection({required this.children});

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

class _ErrorState extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.primaryContainer),
          const SizedBox(height: 16),
          Text(
            message ?? 'Error al cargar el perfil',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}