import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tinta/core/localization/app_strings.dart';
import 'package:tinta/core/ui/theme3material/theme.dart';
import '../../../../core/presentation/components/tinta_background.dart';
import '../../../achievements/data/services/achievement_service.dart';
import '../components/account_info_section.dart';
import '../components/logout_dialog.dart';
import '../components/profile_header_section.dart';
import '../components/settings_section.dart';
import '../viewmodels/user_viewmodel.dart';

/// Pantalla de perfil del usuario (Tab "Yo").
///
/// Campos disponibles del backend Identity:
/// id, email, name, role, email_verified, avatar_url, language,
/// created_at, updated_at.
///
/// Refactor: la vista bajó de 547 → ~110 líneas. Solo orquesta 3
/// secciones (`ProfileHeaderSection`, `AccountInfoSection`,
/// `SettingsSection`) y delega el logout a `LogoutDialog`. Los widgets
/// helper (`_InfoCard`, `_InfoRow`, `_MenuSection`) se movieron dentro
/// de sus componentes correspondientes.
class UserView extends StatefulWidget {
  const UserView({Key? key}) : super(key: key);

  @override
  State<UserView> createState() => _UserViewState();
}

class _UserViewState extends State<UserView> {
  int _achievementPoints = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<UserViewModel>()
          .loadProfile()
          .then((_) => _loadAchievementPoints());
    });
  }

  Future<void> _loadAchievementPoints() async {
    final userId = context.read<UserViewModel>().profile?.id;
    if (userId == null) return;
    final points = await AchievementService.getTotalPoints(userId);
    if (mounted) setState(() => _achievementPoints = points);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(AppStrings.of(context).myProfile),
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
            child: SafeArea(child: _buildContent(context, vm)),
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
      return _ErrorState(message: vm.errorMessage, onRetry: vm.loadProfile);
    }

    final profile = vm.profile;
    if (profile == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: vm.loadProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Cada sección se dibuja sola — este build solo orquesta.
            ProfileHeaderSection(
              profile: profile,
              achievementPoints: _achievementPoints,
              // Reenvío al viewmodel — `updateProfile` regresa
              // `Future<bool>`, que es lo que espera EditProfileSheet.
              onSaveEdit: ({name, language}) => context
                  .read<UserViewModel>()
                  .updateProfile(name: name, language: language),
            ),
            const SizedBox(height: 28),
            AccountInfoSection(profile: profile),
            const SizedBox(height: 32),
            SettingsSection(
              profile: profile,
              achievementPoints: _achievementPoints,
              // Al volver de "Logros" recargo los puntos.
              onLogoutRequested: () => LogoutDialog.show(context),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

/// Estado de error cuando falla la carga inicial del perfil.
///
/// Lo mantengo aquí porque solo aplica a esta vista y depende de su
/// callback `onRetry` — sacarlo a un componente propio no aportaría
/// reuso.
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
          Icon(
            Icons.person_off_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
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