import 'package:flutter/material.dart';

import '../../../features/legal/data/services/disclaimer_service.dart';
import '../../../features/tutorAI/data/services/model_download_service.dart';
import '../../../features/user/presentation/viewmodels/user_viewmodel.dart';
import '../../di/service_locator.dart';
import '../../network/http_client.dart';
import '../../network/session_storage.dart';
import '../../routing/app_routes.dart';

/// Primera pantalla que se muestra al abrir la app.
///
/// Revisa primero el disclaimer legal (una sola vez por dispositivo) y
/// luego si hay una sesión guardada:
///   - Si hay tokens guardados y el perfil carga bien → entra directo a
///     Home (sin pedir login otra vez).
///   - Si no hay sesión, o los tokens ya expiraron → manda a /login.
///
/// Antes vivía como `_SplashGate` privada dentro de `main.dart`. Ahora
/// es pública y vive en `core/presentation/views/` para que el router
/// pueda importarla sin tener que exponer todo el bootstrap de la app.
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkSession());
  }

  // Precarga del modelo de tutor local — arranca en background y no
  // bloquea el flujo. Si falla, el usuario entra a Home sin modelo listo.
  void _preloadTutorModel() {
    final downloadService = sl<ModelDownloadService>();
    downloadService.restoreState().then((_) {
      downloadService.startDownload();
    });
  }

  Future<void> _checkSession() async {
    // 1. Disclaimer legal — se pregunta UNA sola vez por dispositivo,
    //    antes que cualquier otra cosa (incluso antes de saber si hay
    //    sesión guardada).
    final accepted = await DisclaimerService.hasAccepted();
    if (!accepted) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.disclaimer);
      return;
    }

    // 2. ¿Hay sesión guardada?
    final session = await SessionStorage.load();
    if (session == null) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }

    // 3. Inyecto los tokens guardados en el cliente HTTP compartido.
    sl<ApiClient>().setTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );

    // 4. Intento cargar el perfil — si el token ya expiró, limpio y
    //    mando a login.
    try {
      final userVm = sl<UserViewModel>();
      await userVm.loadProfile();

      final userId = userVm.profile?.id;
      if (userId == null) throw Exception('Perfil no disponible');

      if (!mounted) return;

      _preloadTutorModel();
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } catch (_) {
      await SessionStorage.clear();
      sl<ApiClient>().clearTokens();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _AppLogo(colorScheme: cs),
            const SizedBox(height: 16),
            // Uso displaySmall del tema — antes hardcodeaba PlusJakartaSans
            // + w800 + fontSize 32 inline.
            Text(
              'tinta',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: const Color(0xFFE8EAE6),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: cs.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Logo de la app con fallback si el asset falla.
class _AppLogo extends StatelessWidget {
  final ColorScheme colorScheme;
  const _AppLogo({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
      child: Image.asset(
        'assets/icon/icon.png',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: colorScheme.primary,
          child: const Icon(
            Icons.auto_stories_rounded,
            color: Colors.white,
            size: 36,
          ),
        ),
      ),
    );
  }
}