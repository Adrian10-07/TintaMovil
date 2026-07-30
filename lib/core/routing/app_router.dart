import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../di/service_locator.dart';
import '../presentation/views/main_tab_shell.dart';
import '../presentation/views/splash_view.dart';
import '../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../features/auth/presentation/views/login_view.dart';
import '../../features/auth/presentation/views/register_view.dart';
import '../../features/home/presentation/views/book_detail_view.dart';
import '../../features/legal/presentation/views/disclaimer_view.dart';
import '../../features/reader/presentation/views/reader_view.dart';
import 'app_routes.dart';
import 'auth_navigation.dart';

/// Registro central de rutas de la app.
///
/// Sigue usando el patrón **Named Routes / Navigator 1.0** (map
/// `String → WidgetBuilder`). Antes vivía inline dentro de `TintaApp`
/// en `main.dart`, ocupando ~35 líneas del build. Ahora está en un solo
/// lugar y agregar/quitar rutas no toca `main.dart` ni `TintaApp`.
///
/// Si el día de mañana se migra a `go_router` o `Router 2.0`
/// declarativo, este archivo es el único punto de cambio.
class AppRouter {
  AppRouter._();

  /// Ruta con la que arranca la app.
  static const String initialRoute = AppRoutes.splash;

  /// Mapa completo de rutas. Se pasa a `MaterialApp.routes`.
  ///
  /// Los ChangeNotifierProviders de auth se crean por ruta (no globales)
  /// porque el AuthViewModel solo tiene sentido durante login/registro y
  /// así se libera cuando el usuario ya entró.
  static Map<String, WidgetBuilder> routes() => {
    AppRoutes.splash: (_) => const SplashView(),
    AppRoutes.disclaimer: (_) => _disclaimerRoute(),
    AppRoutes.login: (_) => _loginRoute(),
    AppRoutes.register: (_) => _registerRoute(),
    AppRoutes.home: (_) => const MainTabShell(),
    AppRoutes.bookDetail: (_) => const BookDetailView(),
    AppRoutes.reader: (_) => const ReaderView(),
  };

  // ── Builders privados por ruta ──────────────────────────────────────
  //
  // Extraje cada builder complejo a su propio método para que la lista
  // de arriba se lea de un vistazo. Cada método arma sus providers y
  // callbacks propios (SRP).

  static Widget _disclaimerRoute() {
    return Builder(
      builder: (ctx) => DisclaimerView(
        onAccepted: () =>
            Navigator.pushReplacementNamed(ctx, AppRoutes.splash),
      ),
    );
  }

  static Widget _loginRoute() {
    return ChangeNotifierProvider<AuthViewModel>(
      create: (_) => sl<AuthViewModel>(),
      child: Builder(
        builder: (ctx) => LoginView(
          viewModel: ctx.read<AuthViewModel>(),
          onNavigateToRegister: () =>
              Navigator.pushNamed(ctx, AppRoutes.register),
          onLoginSuccess: () => AuthNavigation.afterAuthSuccess(ctx),
        ),
      ),
    );
  }

  static Widget _registerRoute() {
    return ChangeNotifierProvider<AuthViewModel>(
      create: (_) => sl<AuthViewModel>(),
      child: Builder(
        builder: (ctx) => RegisterView(
          viewModel: ctx.read<AuthViewModel>(),
          onNavigateToLogin: () => Navigator.pop(ctx),
          onRegisterSuccess: () =>
              AuthNavigation.afterAuthSuccess(ctx, isNewAccount: true),
        ),
      ),
    );
  }
}