import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'core/di/service_locator.dart';
import 'core/ui/theme3material/theme.dart';

import 'features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'features/user/presentation/viewmodels/user_viewmodel.dart';
import 'features/clubs/presentation/viewmodels/clubs_viewmodel.dart';
import 'core/network/session_storage.dart';
import 'core/network/http_client.dart';

import 'features/auth/presentation/views/login_view.dart';
import 'features/auth/presentation/views/register_view.dart';
import 'features/home/presentation/views/book_detail_view.dart';
import 'features/reader/presentation/views/reader_view.dart';
import 'core/presentation/views/main_tab_shell.dart';
import 'core/settings/app_settings_controller.dart';
import 'features/legal/data/services/disclaimer_service.dart';
import 'features/legal/presentation/views/disclaimer_view.dart';

// ── Inicialización del motor Gemma on-device ─────────────────────────
import 'package:flutter_gemma/core/api/flutter_gemma.dart';
import 'features/tutorAI/data/datasources/tutor_llm_datasource.dart';
import 'features/tutorAI/data/services/model_download_service.dart';

/// Observer global de navegación. Permite que pantallas como Home se
/// enteren cuando vuelven a quedar visibles tras un pop (por ejemplo, al
/// regresar de leer un libro), sin importar cuántas rutas intermedias se
/// hayan apilado encima.
final RouteObserver<PageRoute> appRouteObserver = RouteObserver<PageRoute>();

/// Controlador global de apariencia (tema + tamaño de texto). Se carga
/// una sola vez antes de arrancar la app para que no haya parpadeo entre
/// el tema por defecto y el que el usuario había elegido.
final AppSettingsController appSettings = AppSettingsController();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa el motor de flutter_gemma ANTES de setupServiceLocator(),
  // ya que GemmaFlutterTutorDatasource depende de que esto se haya
  // ejecutado para poder descargar/activar el modelo local.
  FlutterGemma.initialize(
    huggingFaceToken: const String.fromEnvironment('HUGGINGFACE_TOKEN'),
    maxDownloadRetries: 10,
  );

  setupServiceLocator();
  await appSettings.load();
  runApp(const TintaApp());
}

/// Se llama tras login o registro exitoso. Ya no pasa por ninguna
/// encuesta intermedia (se quitó la de Knowledge Base) — va directo a
/// Home siempre. Aprovecha para disparar el precargado de Gemma en
/// background, sin bloquear la navegación.
Future<void> _afterAuthSuccess(
    BuildContext ctx, {
      bool isNewAccount = false,
    }) async {
  if (!ctx.mounted) return;

  sl<ModelDownloadService>().restoreState().then((_) {
    sl<ModelDownloadService>().startDownload();
  });

  Navigator.pushReplacementNamed(ctx, '/home');
}

/// Primera pantalla que se muestra al abrir la app.
/// Revisa primero el disclaimer legal (una sola vez por dispositivo) y
/// luego si hay una sesión guardada:
///   - Si hay tokens guardados y el perfil carga bien → entra directo a
///     Home (sin pedir login otra vez).
///   - Si no hay sesión, o los tokens ya expiraron → manda a /login.
class _SplashGate extends StatefulWidget {
  const _SplashGate();

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkSession());
  }

  void _preloadTutorModel() {
    final downloadService = sl<ModelDownloadService>();
    downloadService.restoreState().then((_) {
      downloadService.startDownload();
    });
  }

  Future<void> _checkSession() async {
    // Primero, el disclaimer legal — se pregunta UNA sola vez por
    // dispositivo, antes que cualquier otra cosa (incluso antes de
    // saber si hay sesión guardada).
    final accepted = await DisclaimerService.hasAccepted();
    if (!accepted) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/disclaimer');
      return;
    }

    final session = await SessionStorage.load();

    if (session == null) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    // Inyecta los tokens guardados en el cliente HTTP compartido.
    sl<ApiClient>().setTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );

    try {
      final userVm = sl<UserViewModel>();
      await userVm.loadProfile();

      final userId = userVm.profile?.id;
      if (userId == null) throw Exception('Perfil no disponible');

      if (!mounted) return;

      _preloadTutorModel();
      Navigator.pushReplacementNamed(context, '/home');
    } catch (_) {
      // El token guardado ya no sirve (expiró o fue revocado):
      // limpiamos la sesión y regresamos a login.
      await SessionStorage.clear();
      sl<ApiClient>().clearTokens();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class TintaApp extends StatelessWidget {
  const TintaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserViewModel>(create: (_) => sl<UserViewModel>()),
        ChangeNotifierProvider<ClubsViewModel>(create: (_) => sl<ClubsViewModel>()),
        ChangeNotifierProvider<AppSettingsController>.value(value: appSettings),
      ],
      child: Builder(
        builder: (context) {
          return AnimatedBuilder(
            animation: appSettings,
            builder: (context, _) {
              final theme = MaterialTheme(MaterialTheme.tintaTextTheme);

              ThemeData selectedTheme;
              switch (appSettings.theme) {
                case AppThemeOption.light:
                  selectedTheme = theme.light();
                  break;
                case AppThemeOption.dark:
                  selectedTheme = theme.dark();
                  break;
                case AppThemeOption.blue:
                  selectedTheme = theme.blue();
                  break;
                case AppThemeOption.superBlack:
                  selectedTheme = theme.superBlack();
                  break;
              }

              return MaterialApp(
                title: 'Tinta',
                debugShowCheckedModeBanner: false,
                navigatorObservers: [appRouteObserver],
                theme: selectedTheme,
                // Selección explícita del usuario, no depende del tema
                // del sistema — por eso theme==darkTheme siempre.
                darkTheme: selectedTheme,
                themeMode: ThemeMode.light,
                // Aplica el tamaño de texto elegido en Apariencia a TODA
                // la app, sin tener que tocar cada widget de texto.
                builder: (context, child) {
                  final mediaQuery = MediaQuery.of(context);
                  return MediaQuery(
                    data: mediaQuery.copyWith(
                      textScaler: TextScaler.linear(appSettings.textSize.scaleFactor),
                    ),
                    child: child!,
                  );
                },
                initialRoute: '/splash',
                routes: {
                  '/splash': (_) => const _SplashGate(),
                  '/disclaimer': (_) => Builder(
                    builder: (ctx) => DisclaimerView(
                      onAccepted: () =>
                          Navigator.pushReplacementNamed(ctx, '/splash'),
                    ),
                  ),
                  '/login': (_) => ChangeNotifierProvider<AuthViewModel>(
                    create: (_) => sl<AuthViewModel>(),
                    child: Builder(
                      builder: (ctx) => LoginView(
                        viewModel: ctx.read<AuthViewModel>(),
                        onNavigateToRegister: () => Navigator.pushNamed(ctx, '/register'),
                        onLoginSuccess: () => _afterAuthSuccess(ctx),
                      ),
                    ),
                  ),
                  '/register': (_) => ChangeNotifierProvider<AuthViewModel>(
                    create: (_) => sl<AuthViewModel>(),
                    child: Builder(
                      builder: (ctx) => RegisterView(
                        viewModel: ctx.read<AuthViewModel>(),
                        onNavigateToLogin: () => Navigator.pop(ctx),
                        onRegisterSuccess: () =>
                            _afterAuthSuccess(ctx, isNewAccount: true),
                      ),
                    ),
                  ),
                  '/home': (_) => const MainTabShell(),
                  '/book-detail': (_) => const BookDetailView(),
                  '/reader': (_) => const ReaderView(),
                },
              );
            },
          );
        },
      ),
    );
  }
}