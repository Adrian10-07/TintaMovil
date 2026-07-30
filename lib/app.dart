import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/di/service_locator.dart';
import 'core/routing/app_router.dart';
import 'core/routing/route_observers.dart';
import 'core/settings/app_settings_controller.dart';
import 'core/ui/theme3material/theme_resolver.dart';
import 'features/clubs/presentation/viewmodels/clubs_viewmodel.dart';
import 'features/user/presentation/viewmodels/user_viewmodel.dart';
import 'globals.dart';

/// Widget raíz de la app.

class TintaApp extends StatelessWidget {
  const TintaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserViewModel>(
          create: (_) => sl<UserViewModel>(),
        ),
        ChangeNotifierProvider<ClubsViewModel>(
          create: (_) => sl<ClubsViewModel>(),
        ),
        ChangeNotifierProvider<AppSettingsController>.value(
          value: appSettings,
        ),
      ],
      child: AnimatedBuilder(
        animation: appSettings,
        builder: (context, _) {

          final theme = ThemeResolver.resolve(appSettings.theme);

          return MaterialApp(
            title: 'Tinta',
            debugShowCheckedModeBanner: false,
            navigatorObservers: [appRouteObserver],
            theme: theme,
            // Selección explícita del usuario, no depende del tema del
            // sistema — por eso theme == darkTheme siempre.
            darkTheme: theme,
            themeMode: ThemeMode.light,
            // Clave para que DevicePreview funcione: hereda su MediaQuery.
            useInheritedMediaQuery: true,
            locale: DevicePreview.locale(context),
            // Encadeno appBuilder de DevicePreview con el ajuste global de
            // tamaño de texto, para que ambos convivan.
            builder: (context, child) {
              final wrapped = DevicePreview.appBuilder(context, child);
              final mq = MediaQuery.of(context);
              return MediaQuery(
                data: mq.copyWith(
                  textScaler: TextScaler.linear(
                    appSettings.textSize.scaleFactor,
                  ),
                ),
                child: wrapped,
              );
            },
            initialRoute: AppRouter.initialRoute,
            routes: AppRouter.routes(),
          );
        },
      ),
    );
  }
}